#!/usr/bin/env bash

####################################################################################
# Slack Bash console script for sending messages via Slack.
# Inspired and based on https://gist.github.com/andkirby/67a774513215d7ba06384186dd441d9e
####################################################################################
# Installation
#       $ curl -s https://raw.githubusercontent.com/demmonico/bash-alarm/master/channels/slack.sh --output /usr/bin/slack && chmod +x /usr/bin/slack
# [opt] ### to define some ENV vars
# [opt] $ touch ./.slackrc && nano ./.slackrc
# [opt] $ cat channels/.slackrc <<EOL
#         APP_SLACK_WEBHOOK='https://hooks.slack.com/services/<WEBHOOK_KEY>'
#         APP_SLACK_CHANNEL='#test-alert'
#         APP_SLACK_USERNAME='AlarMan'
#         APP_SLACK_ICON_EMOJI=':shipit:'
#         EOL
# [opt] ### you may also declare them in $HOME/.slackrc file.
#
# VARIABLES
#
# Please declare environment variables:
#   - APP_SLACK_WEBHOOK
#   - APP_SLACK_CHANNEL (optional)
#   - APP_SLACK_USERNAME (optional)
#   - APP_SLACK_ICON_EMOJI (optional)
####################################################################################
# USAGE
# Send message to slack channel/user
#   Send a message to the channel #ch-01
#     $ slack '#ch-01' 'Some message here.'
#
#   Send a message to the default channel (it must be declared in APP_SLACK_CHANNEL).
#     $ slack  MESSAGE
####################################################################################

# publish env vars from the ~/.slackrc file
if [ -f $HOME/.slackrc ]; then
    . $HOME/.slackrc
fi
# publish env vars from the ./.slackrc file
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f $DIR/.slackrc ]; then
    . $DIR/.slackrc
fi

####################################################################################

MESSAGE_HEADER_ICON='https://image.freepik.com/free-vector/illustration-red-flasher-flashing-beacon-with-siren-police-ambulance-cars_1441-2247.jpg'
MESSAGE_HEADER_TEXT='Alert script notification:'

####################################################################################

set -o pipefail
set -o errexit
set -o nounset
#set -o xtrace

_init_params() {
  # you may declare ENV vars in /etc/profile.d/slack.sh
  if [ -z "${APP_SLACK_WEBHOOK:-}" ]; then
    echo 'error: Please configure Slack environment variable: ' > /dev/stderr
    echo '  APP_SLACK_WEBHOOK' > /dev/stderr
    exit 2
  fi

  APP_SLACK_USERNAME=${APP_SLACK_USERNAME:-$(hostname | cut -d '.' -f 1)}
  
  APP_SLACK_ICON_EMOJI=${APP_SLACK_ICON_EMOJI:-:slack:}
  if [ -z "${1:-}" ]; then
    echo 'error: Missed required arguments.' > /dev/stderr
    echo 'note: Please follow this example:' > /dev/stderr
    echo '  $ slack.sh "#CHANNEL1,CHANNEL2" Some message here. ' > /dev/stderr
    exit 3
  fi

  slack_channels=(${APP_SLACK_CHANNEL:-})
  if [ "${1::1}" == '#' ] || [ "${1::1}" == '@' ]; then
    # explode by comma
    IFS=',' read -r -a slack_channels <<< "${1}"
    shift
  fi
  slack_message_from="$( _getHostname ) ($( _getIp ))"
  slack_message=${@}
}

_getHostname() {
  local CMD="hostname | cut -d '.' -f 1"
  eval $CMD
}

_getIp() {
  local CMD="hostname --all-ip-addresses | sed -E 's/[[:space:]]/, /g' | sed -E 's/,[[:space:]]$//g'"
  if [[ $OSTYPE == darwin* ]]; then
      CMD="ipconfig getifaddr en0"
  fi
  command $CMD
}

_send_message() {
  local channel=${1}
  echo -n 'Sending to '${channel}'... '

  #    "$(printf 'payload={"text": "%s", "channel": "%s", "color": "%s", "username": "%s", "as_user": "true", "link_names": "true", "icon_emoji": "%s" }' \

  local OPTIONS_VIEW="$(printf '"icon_emoji": "%s"' \
        "${APP_SLACK_ICON_EMOJI}" \
    )"
  local OPTIONS_APP="$(printf '"username": "%s", "as_user": "true", "link_names": "true"' \
        "${APP_SLACK_USERNAME}" \
    )"
  local MESSAGE_HEADER="$(printf '{
          "type": "context",
          "elements": [
            {
              "type": "image",
              "image_url": "%s",
              "alt_text": "MESSAGE_HEADER_ICON"
            },
            {
              "type": "mrkdwn",
              "text": "%s"
            }
          ]
        }' \
        "${MESSAGE_HEADER_ICON}" \
        "${MESSAGE_HEADER_TEXT}" \
    )"
  local MESSAGE_DIVIDER='{"type": "divider"}'
  local MESSAGE="$(printf '"blocks": [
          %s,
          {
            "type": "section",
            "text": {
              "text": "%s",
              "type": "mrkdwn"
            }
          },
          {
            "type": "context",
            "elements": [
              {
                "type": "image",
                "image_url": "https://image.freepik.com/free-vector/geographic-location-system_24877-52112.jpg",
                "alt_text": "location pin"
              },
              {
                "type": "mrkdwn",
                "text": "Location: *%s*"
              }
            ]
          },
          %s
        ]' \
        "${MESSAGE_HEADER}" \
        "${slack_message}" \
        "${slack_message_from}" \
        "${MESSAGE_DIVIDER}" \

    )"
  local PAYLOAD="$(printf 'payload={"channel": "%s", %s, %s, %s }' \
        "${channel}" \
        "${OPTIONS_VIEW}" \
        "${OPTIONS_APP}" \
        "${MESSAGE}" \
    )"

  curl --silent --data-urlencode "${PAYLOAD}" "${APP_SLACK_WEBHOOK}" || true
  echo
}

_send_message_to_channels() {
  for channel in "${slack_channels[@]:-}"; do
    _send_message "${channel}"
  done
}



slack() {
  # Set magic variables for current file & dir
  __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  __file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
  readonly __dir __file

  cd ${__dir}

  if [ -f $(cd; pwd)/.slackrc ]; then
    . $(cd; pwd)/.slackrc
  fi

  declare -a slack_channels

  _init_params ${@}
  _send_message_to_channels
}

########
# init #
########
slack ${@}
