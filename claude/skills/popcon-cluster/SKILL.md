---
name: popcon-cluster
description: Manage named POPCON HCI cluster records, collected context, service access values, and OpenStack accounts. Use when the user asks to register, update, delete, list, refresh, or use a named environment such as megabox through the harness.
---

# POPCON Cluster

이 스킬은 하네스의 클러스터 registry로 POPCON HCI 원격 클러스터를 이름으로 다룰 때 사용한다.

## 상태

클러스터 상태 디렉터리는 기본적으로 `~/.popcon/cluster`다.

registry 파일은 상태 디렉터리의 `remotes/` 아래에 둔다.

```text
remotes/index.json
remotes/NAME/connection.json       # SSH 설정, 수집 context, access 값, OpenStack 계정
remotes/NAME/known_hosts
remotes/NAME/artifacts/
```

`connection.json`과 수집 artifacts는 로컬 상태 파일이다. Git에 추가하지 않는다.

## 등록

하네스 repo root에서 스크립트를 실행한다.

SSH 명령으로 클러스터를 등록한다.

```sh
python3 scripts/cluster/registry.py add megabox --from-ssh 'ssh -p2022 popcon@<CLUSTER_HOST>'
```

사용자명, 비밀번호, 포트를 생략하면 각각 `popcon`, `Admin123!`, `22`를 기본값으로 저장한다.
비밀번호를 명시할 때는 `--ssh-password`를 사용한다.

```sh
python3 scripts/cluster/registry.py add pink \
  --from-ssh 'ssh popcon@192.168.246.10' \
  --ssh-password 'Admin123!'
```

사용자가 클러스터 등록을 요청하면 접속 정보를 저장한 뒤 가능한 context 수집을 바로 시도한다.

```sh
python3 scripts/cluster/collect-remote-context.py refresh megabox
```

등록 정보를 수정한다.

```sh
python3 scripts/cluster/registry.py update megabox --ssh-port 2022
```

목록과 상세 정보를 확인한다.

```sh
python3 scripts/cluster/registry.py list
python3 scripts/cluster/registry.py show megabox
```

## 컨텍스트 갱신

등록 후 클러스터 정보를 사용하기 전에 컨텍스트를 갱신한다.

```sh
python3 scripts/cluster/collect-remote-context.py refresh megabox
```

이 명령은 원격 클러스터에서 collector를 실행하고 수집 결과를 `connection.json`의 `context`에 저장한다.
원격 `psm-cm` pod의 `admin-openrc.sh`는 먼저 아래 명령으로 읽는다.

```sh
kubectl exec -it deployments/psm-cm -c psm-cm -- cat /etc/kolla/admin-openrc.sh
```

여기서 읽은 OpenStack admin 계정은 같은 `connection.json`의 `openstack_accounts`에도 저장한다.

## 접속 정보

서비스 접속 정보는 `scripts/cluster/access.py`로 저장한다. 값은 문자열로 저장하며, `remotes/NAME/connection.json`의 `access` 아래에 `SERVICE.FIELD` 형태의 key를 사용한다.

```sh
python3 scripts/cluster/access.py set megabox mongodb.endpoint '<MONGODB_ENDPOINT>'
python3 scripts/cluster/access.py set megabox mongodb.username admin
python3 scripts/cluster/access.py set megabox mongodb.password 'Admin123!'
```

저장된 값을 확인한다.

```sh
python3 scripts/cluster/access.py list megabox
python3 scripts/cluster/access.py show megabox mongodb
```

## OpenStack 계정

OpenStack 계정 정보는 `scripts/cluster/openstack-account.py`로 저장한다. 계정은 `remotes/NAME/connection.json`의 `openstack_accounts` 아래에 둔다.
계정별 저장값은 `name`, `project_name`, `username`, `password`만 둔다.
`--project`를 생략하면 context 계정과 같은 username일 때는 context의 project를 쓰고, 아니면 username을 project로 저장한다.
`auth_url`은 사용자에게 입력받지 않는다. 항상 `connection.json`의 `context.openstack_access.auth_url`을 쓰며, 값이 없으면 context 갱신으로 직접 확인한다.

```sh
python3 scripts/cluster/openstack-account.py add megabox \
  --username admin \
  --password 'Admin123!'
```

저장된 계정을 확인한다.

```sh
python3 scripts/cluster/openstack-account.py list megabox
python3 scripts/cluster/openstack-account.py show megabox admin/admin
```

## 클러스터 사용

사용자가 등록된 클러스터 이름을 말하면 해당 클러스터의 `connection.json`을 읽는다.

원격 명령은 아래처럼 실행한다.

```sh
python3 scripts/cluster/run.py megabox -- kubectl get nodes
```

OpenStack CLI는 아래처럼 실행한다.

```sh
python3 scripts/cluster/openstack.py megabox -- server list
python3 scripts/cluster/openstack.py --account admin/admin megabox -- server list
```

## 외부 클러스터 조회

등록된 외부 클러스터를 분석할 때는 `run.py`로 원격 읽기 전용 명령을 실행하고, OpenStack CLI는 `openstack.py`를 사용한다.
DB와 OpenSearch 접속값은 `connection.json`의 `context.service_endpoints`에 저장된 host/url, port, username, password 값을 기준으로 사용한다.
Kolla 파일 로그는 `/var/log/kolla`가 Docker volume symlink일 수 있으므로 직접 `find` 결과가 비면 `sudo -n find -L /var/log/kolla ...`처럼 symlink를 따라 읽고, 컨테이너 로그는 `docker logs`로 조회한다.

## 주의

서비스 재시작, DB 쓰기, OpenStack 상태 변경, 노드 재부팅, 패키지 변경, 설정 변경은 사용자의 명시적인 승인 없이 실행하지 않는다.
