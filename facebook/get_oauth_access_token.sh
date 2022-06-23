#!/usr/bin/env bash

set -euo pipefail

cat << EOF
WHAT: Call the Facebook API to get an OAuth Access Token
WHY: So that we can authenticate users on our service/app using Facebook and
get access to user Facebook data.
HOW: Hit ENTER and keep going 👇👇👇
EOF
read -r

cat << EOF
The first thing we need to do is to create Facebook app:
https://developers.facebook.com/docs/development
This is a pre-requisite to interact with Facebook's API so that Facebook knows
who we are etc, etc.
Once the app is created we would need the app ID and secret.
EOF
read -r

: "${FB_APP_ID:?}"
: "${FB_APP_SECRET:?}"

cat << EOF
Next we need to add the Facebook Login product to our app and configure the
OAuth Redirect URI: https://developers.facebook.com/products/facebook-login/
The Redirect URI is Redirect endpoint we will have to write later on that
Facebook can call us there and provide us with an Authorisation Code that we
will be able to exchange against an Access Token later on.
EOF
read -r

REDIRECT_URI=https://diegolemos.net/
# ENCODED_URI="$(echo "$REDIRECT_URI" | jq -sRr '@uri')"
STATE=$RANDOM

cat << EOF
We start by calling the Authorisation endpoint to get an Authorisation Code. At
this point the user will be asked if they want to login to our service/app with
their Facebook account and what data they want to share with us.
EOF
read -r

( set -x
  open "https://www.facebook.com/v6.0/dialog/oauth?client_id=$FB_APP_ID&redirect_uri=$REDIRECT_URI&state=$STATE"
)

cat << EOF
Once you've logged in, you will be redirected to "$REDIRECT_URI". The URL in
the browser should have 2 extra parameters: code and state.
EOF
read -r -p 'Enter the URL that you have been redirected to: ' uri_with_auth_code

AUTH_CODE="$(echo "${uri_with_auth_code/#REDIRECT_URI/}" | sed -n -E 's/.*code=(.*)&.*/\1/p')"

cat <<EOF

Now that we have our Authorisation Code, we can request an Access Token that
will allow us to impersonate the user. In order to do that we need to call
Token endpoint (which's normally a POST but Facebook implements it as a GET).
EOF
read -r

response=$( set -x
  curl -s \
    --data-urlencode "redirect_uri=$REDIRECT_URI" \
    --data-urlencode "client_id=$FB_APP_ID" \
    --data-urlencode "client_secret=$FB_APP_SECRET" \
    --data-urlencode "code=$AUTH_CODE" \
    https://graph.facebook.com/v6.0/oauth/access_token)

ACCESS_TOKEN="$( echo "$response" | jq -r '.access_token' )"

cat << EOF

Yay!!! Now that we have our Access Token we can call the Facebook API on behalf of
our user.
EOF
read -r

( set -x
  curl \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    https://graph.facebook.com/me
)
