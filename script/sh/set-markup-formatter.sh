#!/bin/bash

set -e


# FIXME: in 2.0 the default sec-conf form values changed (to have
# security enabled by default). And this curl update no longer works

scriptname=$(basename $0)
c=0
test -n "$tag" || . ./vars.sh "$@"
#test -z "$c" || shift $c


test -n "$JENKINS_URL" || warn "No JENKINS_URL env" 1


echo "Configuring markup formatter setting ($JENKINS_URL)"

# Change Markup validator to "Safe HTML" in Global Security screen
curl -sf -X post -L -D - \
		-o /tmp/$scriptname-1-$(uuidgen).curlout \
    -d json='{"": "1", "markupFormatter": {"disableSyntaxHighlighting": false, "stapler-class": "hudson.markup.RawHtmlMarkupFormatter", "$class": "hudson.markup.RawHtmlMarkupFormatter"}, "hudson-security-csrf-GlobalCrumbIssuerConfiguration": {}, "jenkins-model-DownloadSettings": {"useBrowser": false}, "core:apply": "true"}' \
    $JENKINS_URL/configureSecurity/configure \
      || err "cURL returned error $?" $?


