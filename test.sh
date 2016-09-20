

case "$1" in test-api-user-nonempty )
  test -n "$api_user" || exit 1
  ;;
esac

