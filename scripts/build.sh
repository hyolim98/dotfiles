#!/bin/bash

branch=feature_r197946

cd admin-core
cd phci-idl

# phci-idl
echo "[phci-idl] pull feature_r197946 branch"
git fetch origin
git reset --hard origin/$branch

cd ../
# admin-core
echo "[admin-core] pull feature_r197946 branch"
git fetch origin
git reset --hard origin/$branch

echo "make phci-idl"
make phci-idl

cd cmd/controllerManager
echo "build admin-core"
make && make mk-docker-img && make push-docker-img

cd ../api-gateway
make && make mk-docker-img && make push-docker-img
