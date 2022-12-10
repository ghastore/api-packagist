FROM alpine

LABEL "name"="Packagist API"
LABEL "description"=""
LABEL "maintainer"=""
LABEL "repository"=""
LABEL "homepage"="https://github.com/ghastore"

COPY *.sh /
RUN apk add --no-cache bash curl git git-lfs jq

ENTRYPOINT ["/entrypoint.sh"]
