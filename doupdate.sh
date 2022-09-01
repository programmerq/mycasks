#!/bin/bash -x

### taken from https://stackoverflow.com/a/25180186/4930423

function try()
{
    [[ $- = *e* ]]; SAVED_OPT_E=$?
    set +e
}

function throw()
{
    exit $1
}

function catch()
{
    export ex_code=$?
    (( $SAVED_OPT_E )) && set +e
    return $ex_code
}

function throwErrors()
{
    set -e
}

function ignoreErrors()
{
    set +e
}

### script follows

repo=webrecorder/archiveweb.page
repourl=https://api.github.com/repos/$repo
caskname=archiveweb_page
me=$(basename $0)
DIR=$(mktemp -d -t $me)
try
(
	cd $DIR
	curl -sSL $repourl > repo.json || throw 50
	export caskdescription=$(cat repo.json | yq .description) || throw 51
	export caskname=$(cat repo.json | yq .name | sed 's/\./_/g') || throw 52
	export caskhomepage=$(cat repo.json | yq .html_url) || throw 53
	export caskapp="ArchiveWeb.page.app" 


	curl -sSL $repourl/releases > releases.json || throw 100
	export latest=$(cat releases.json | yq '.[].tag_name' | sort -V | tail -n 1) || throw 110
	export caskversion=$(echo $latest | sed 's/^v//g')
	export URL=$(cat releases.json | yq -P ".[] | select(.tag_name == \"$latest\") | .assets[] | select(.browser_download_url | test(\".*.dmg$\")) | .browser_download_url") || throw 120
	export SHA=$(curl -sSL $URL | shasum -a 256 | awk '{print $1}') || throw 130

	envsubst < $OLDPWD/cask.template > $OLDPWD/Casks/$caskname.rb || throw 140
)
catch || (
	echo "failed"
)
rm -rf $DIR
