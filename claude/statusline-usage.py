#!/usr/bin/env python3
"""Claude Code statusLine: 현재 대화 컨텍스트 + 실제 /usage 한도(5h·weekly).

ctx  = 현재 세션 transcript 의 컨텍스트 점유율 (로컬 계산)
5h   = /api/oauth/usage 의 five_hour.utilization  (= /usage 의 current session)
week = seven_day.utilization                       (= /usage 의 weekly)
usage API 응답은 30초 캐시, 3초 타임아웃, 실패 시 직전 캐시로 폴백.
"""
import sys, os, json, urllib.request
from datetime import datetime, timezone

HOME = os.path.expanduser("~")
CRED = os.path.join(HOME, ".claude", ".credentials.json")
CACHE_DIR = os.path.join(HOME, ".cache", "claude-usage")
USAGE_CACHE = os.path.join(CACHE_DIR, "usage-api-cache.json")
USAGE_TTL = 30  # 초

ANSI = {"dim": "\x1b[2m", "rst": "\x1b[0m",
        "sky": "\x1b[38;5;39m", "rd": "\x1b[31m"}  # mono sky blue + 위험 red

# ---------- 컨텍스트 (로컬) ----------
def window_of(model):
    return 200_000 if "haiku" in (model or "").lower() else 1_000_000  # opus/sonnet 1M

def session_ctx(path):
    """transcript 마지막 assistant 요청의 프롬프트 토큰 = 현재 컨텍스트 점유량."""
    ctx = 0
    try:
        with open(path, errors="ignore") as fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                try:
                    o = json.loads(line)
                except Exception:
                    continue
                if o.get("type") != "assistant":
                    continue
                u = (o.get("message") or {}).get("usage")
                if not u:
                    continue
                cc = u.get("cache_creation") or {}
                cw = (cc.get("ephemeral_5m_input_tokens") or 0) + (cc.get("ephemeral_1h_input_tokens") or 0)
                if not cw:
                    cw = u.get("cache_creation_input_tokens", 0) or 0
                ctx = (u.get("input_tokens", 0) or 0) + (u.get("cache_read_input_tokens", 0) or 0) + cw
    except Exception:
        pass
    return ctx

# ---------- 실제 /usage (서버) ----------
def token():
    try:
        return json.load(open(CRED))["claudeAiOauth"]["accessToken"]
    except Exception:
        return None

def fetch_usage(tok):
    req = urllib.request.Request(
        "https://api.anthropic.com/api/oauth/usage",
        headers={"Authorization": f"Bearer {tok}", "anthropic-beta": "oauth-2025-04-20",
                 "anthropic-version": "2023-06-01", "User-Agent": "claude-cli"})
    with urllib.request.urlopen(req, timeout=3) as r:
        return json.load(r)

def get_usage(now):
    cached = None
    try:
        c = json.load(open(USAGE_CACHE))
        cached = c.get("data")
        if now - c.get("ts", 0) < USAGE_TTL:
            return cached
    except Exception:
        pass
    tok = token()
    if tok:
        try:
            data = fetch_usage(tok)
            os.makedirs(CACHE_DIR, exist_ok=True)
            json.dump({"ts": now, "data": data}, open(USAGE_CACHE, "w"))
            return data
        except Exception:
            pass
    return cached  # 호출 실패 → 직전 캐시(있으면)

# ---------- 렌더 ----------
def bar(frac, n=5):
    frac = max(0.0, min(1.0, frac))
    f = int(round(frac * n))
    return "▪" * f + "▫" * (n - f)

def k(n):
    if n >= 1_000_000: return f"{n/1_000_000:.1f}".rstrip("0").rstrip(".") + "M"
    if n >= 1_000:     return f"{round(n/1000)}k"
    return str(int(n))

def color(f):
    return ANSI["rd"] if f >= 0.8 else ANSI["sky"]  # 평소 sky blue, 위험(≥80%)만 red

def gauge(label, frac, suffix=""):
    f = max(0.0, min(1.0, frac))
    pct = int(round(f * 100))
    s = f" {ANSI['dim']}{suffix}{ANSI['rst']}" if suffix else ""
    return f"{color(f)}{label} {bar(f)} {pct}%{ANSI['rst']}{s}"

def reset_in(iso):
    """resets_at ISO → '↻3h12m' / '↻6d' 형태 남은시간. 실패/만료 시 ''."""
    try:
        secs = (datetime.fromisoformat(iso) - datetime.now(timezone.utc)).total_seconds()
        if secs <= 0:
            return ""
        if secs >= 86400:
            return f"↻{int(secs // 86400)}d"
        h, m = int(secs // 3600), int((secs % 3600) // 60)
        return f"↻{h}h{m:02d}m" if h else f"↻{m}m"
    except Exception:
        return ""

def util(blk):
    """usage 블록 → utilization frac(0~1). 값 없으면 None."""
    if not isinstance(blk, dict):
        return None
    v = blk.get("utilization")
    return (v / 100.0) if isinstance(v, (int, float)) else None

def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        data = {}
    model = data.get("model") or {}
    model_name = model.get("display_name") or model.get("id") or "claude"

    ctx = 0
    tp = data.get("transcript_path")
    if tp and os.path.exists(tp):
        ctx = session_ctx(tp)
    win = window_of(model.get("id") or model_name)

    usage = get_usage(datetime.now().timestamp()) or {}
    fh, sd = usage.get("five_hour") or {}, usage.get("seven_day") or {}

    parts = [f"{ANSI['sky']}◆ {model_name}{ANSI['rst']}",
             gauge("ctx", ctx / win if win else 0, f"{k(ctx)}/{k(win)}")]
    fhf, sdf = util(fh), util(sd)
    if fhf is not None:
        parts.append(gauge("5h", fhf, reset_in(fh.get("resets_at", ""))))
    if sdf is not None:
        parts.append(gauge("week", sdf, reset_in(sd.get("resets_at", ""))))
    if fhf is None and sdf is None:
        parts.append(f"{ANSI['dim']}usage n/a{ANSI['rst']}")
    print(" · ".join(parts))

if __name__ == "__main__":
    try:
        main()
    except Exception:
        print("◆ claude usage")
