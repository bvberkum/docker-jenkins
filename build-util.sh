
api_user= api_secret=

test "$env" = "acc" \
  && ssh_credentials_id=a2165938-7dd3-475e-9102-15191067fd16 \
  || ssh_credentials_id="${hostname}-docker-${1}-ssh-key"

test -n "$ssh_credentials_id" || error "SSH credential ID expected" 1


get_env()
{
  test -n "$env" && log "get-env $env" || err "Missing env name" 1
  test -n "$1" || set -- $env
  test -s ".env-api-$1.sh" || {
    log "Missing .env-api-$1.sh file.."
    log "Enter a new username? (default: jenkins)"
    read confirm

    trueish "$confirm" && {
      log "Enter the username for API use"
      read api_user
    }
    log "Enter the API user key"
    read api_secret

    test -n "$api_user" || error "missing api_user" 89
    store_env $1
  }
  . ./.env-api-$1.sh
  export api_user api_secret JENKINS_URL ssh_credentials_id cname env tag
}

store_env()
{
  test -n "$env" || err store-env 1
  test -n "$1" || set -- $env
  {
    echo api_user=$api_user
    echo api_secret=$api_secret
    echo ssh_credentials_id=$ssh_credentials_id
    echo JENKINS_URL=$JENKINS_URL
    echo cname=$cname
    echo chome=$chome
    echo env=$1
    echo tag=$tag
  } > .env-api-$1.sh
}

clear_env()
{
  test -n "$env" && log "clear-env $env" || err clear-env 1
  test -n "$1" || set -- $env
  test ! -e .env-api-$1.sh || rm -rf .env-api-$1.sh
}

file_for_env()
{
  test -n "$env" || err file-for-env 1
  test -n "$1" || set -- $env
  echo .env-api-$1.sh
}

show_env()
{
  test -n "$env" || err show-env 1
  test -n "$1" || set -- $env
  cat .env-api-$1.sh
}

