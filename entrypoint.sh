#!/bin/sh

if [ -z "$GITHUB_ORGANIZATION" ] && ! [ -z "$GITHUB_OWNER" ] && ! [ -z "$GITHUB_REPOSITORY" ]
then
	registration_url="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPOSITORY}/actions/runners/registration-token"
	export CONFIG_URL="https://github.com/${GITHUB_OWNER}/${GITHUB_REPOSITORY}"		
elif [ -z "$GITHUB_OWNER" ] && [ -z "$GITHUB_REPOSITORY" ] && ! [ -z "$GITHUB_ORGANIZATION" ]
then
	registration_url="https://api.github.com/orgs/${GITHUB_ORGANIZATION}/actions/runners/registration-token"
	export CONFIG_URL="https://github.com/${GITHUB_ORGANIZATION}"
else
	echo "Environment variables were not defined correctly"
	exit 1
fi

echo $GITHUB_PAT
echo "Requesting registration URL at '${registration_url}'"

payload=$(curl -sX POST -H "Authorization: token ${GITHUB_PAT}" ${registration_url})
export RUNNER_TOKEN=$(echo $payload | jq .token --raw-output)

./config.sh \
    --name $(hostname) \
    --token ${RUNNER_TOKEN} \
    --url ${CONFIG_URL} \
    --work ${RUNNER_WORKDIR} \
    --unattended \
    --replace

remove() {
    ./config.sh remove --unattended --token "${RUNNER_TOKEN}"
}

trap 'remove; exit 130' INT
trap 'remove; exit 143' TERM

./run.sh "$*" &

wait $!	
