#!/bin/bash
set -e

if [ -e /vsts/agent ]; then
  export VSO_AGENT_IGNORE=_,MAIL,OLDPWD,PATH,PWD,UBUNTU_VERSION,VSO_AGENT_IGNORE
  if [ -n "$VSTS_AGENT_IGNORE" ]; then
    export VSO_AGENT_IGNORE=$VSO_AGENT_IGNORE,VSTS_AGENT_IGNORE,$VSTS_AGENT_IGNORE
  fi
  trap 'kill -SIGINT $!; exit 130' INT
  trap 'kill -SIGTERM $!; exit 143' TERM
  /vsts/agent/bin/Agent.Listener run & wait $!
  exit $?
fi

if [ -z "$VSTS_ACCOUNT" ]; then
  echo 1>&2 error: missing VSTS_ACCOUNT environment variable
  exit 1
fi

if [ -z "$VSTS_TOKEN" ]; then
  echo 1>&2 error: missing VSTS_TOKEN environment variable
  exit 1
fi

if [ -n "$VSTS_AGENT" ]; then
  export VSTS_AGENT=$(eval echo $VSTS_AGENT)
fi

if [ -n "$VSTS_WORK" ]; then
  export VSTS_WORK=$(eval echo $VSTS_WORK)
  mkdir -p "$VSTS_WORK"
fi

mkdir /vsts/agent
mv /vsts/vsts-agent-linux-x64-2.136.1.tar.gz /vsts/agent
cd /vsts/agent

cleanup() {
  if [ -e "./config.sh" ]; then
    ./bin/Agent.Listener remove --unattended \
      --auth PAT \
      --token "$VSTS_TOKEN"
  fi
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

echo installing VSTS agent...
tar zxvf vsts-agent-linux-x64-2.136.1.tar.gz & wait $!
chgrp -R 0 .
chmod -R g=u .

export VSO_AGENT_IGNORE=_,MAIL,OLDPWD,PATH,PWD,UBUNTU_VERSION,VSTS_AGENT_URL,VSO_AGENT_IGNORE,VSTS_AGENT,VSTS_ACCOUNT,VSTS_TOKEN,VSTS_POOL,VSTS_WORK
if [ -n "$VSTS_AGENT_IGNORE" ]; then
  export VSO_AGENT_IGNORE=$VSO_AGENT_IGNORE,VSTS_AGENT_IGNORE,$VSTS_AGENT_IGNORE
fi

source ./env.sh

./bin/Agent.Listener configure --unattended \
  --agent "${VSTS_AGENT:-$(hostname)}" \
  --url "https://tfs.pine.com" \
  --auth PAT \
  --token "$VSTS_TOKEN" \
  --pool "${VSTS_POOL:-Default}" \
  --work "${VSTS_WORK:-_work}" \
  --replace & wait $!

./bin/Agent.Listener run & wait $!
