#!/bin/bash

# This script will remind you to update the change log and
# to bump the version number of the package

# It will then check that you're logged into AWS (which
# is required to send the Slack notification)

# After those valiations are complete, it will prompt you
# to log into npm and it will then publish the package

# If the publish succeeds, it will send a Slack notification

# You can disable various steps of the script for dry runs
# by setting the following when running the script:
#   SKIP_NPM_LOGIN=1
#   SKIP_NPM_PUBLISH=1
#   SKIP_ALERT=1

function prompt {
    read -p "$1 (Y/N): " confirm &&
    if [[ ! "$confirm" =~ ^[Yy]+([eE][sS])?$ ]]; then
        echo -e "\n⚠️  $2 ⚠️\n"
        exit 1
    fi
}

prompt "Did you update CHANGELOG.md?" "Update CHANGELOG.md before publishing to NPM."

prompt "Did you bump the version number in package.json?" "Bump the version number in package.json before publishing to NPM."

if [ -z "$SKIP_ALERT" ]; then
    # runs the get-user command and throws away output
    # checks for nonzero exit code to determine if the
    # user is logged in or not
    aws iam get-user > /dev/null 2>&1
    if [[ ! $? -eq 0 ]]; then
        echo -e "\n⚠️  Please log into AWS and try again. ⚠️\n"
        exit 1
    fi
else
    echo "Would have checked if you were logged into AWS"
fi

if [ -z "$SKIP_NPM_LOGIN" ]; then
    echo -e "\nLogging into NPM...\n"
    npm login
else
    echo "Would have logged into NPM"
fi

if [ -z "$SKIP_NPM_PUBLISH" ]; then
    echo -e "\nPublishing to NPM...\n"
    npm publish
else
    echo "Would have published to NPM"
fi

if [[ ! $? -eq 0 ]]; then
    echo -e "\n🚨  Publish failed. Please try again. 🚨\n"
    exit 1
fi

PACKAGE_VERSION=$(cat package.json | grep "version" | awk '{print $2}' | sed 's/[",]//g')
CHANGELOG_LINK="<https://gerrit.instructure.com/plugins/gitiles/canvas-lms/+/refs/heads/master/packages/canvas-media/CHANGELOG.md | here>"
SLACK_MESSAGE="canvas-media version $PACKAGE_VERSION has been published to NPM \n\nSee the full list of changes $CHANGELOG_LINK."

if [ -z "$SKIP_ALERT" ]; then
    (
      aws --region us-east-1 sqs send-message \
        --queue-url https://sqs.us-east-1.amazonaws.com/636161780776/slack-lambda \
        --message-body "{\"channel\":\"#ask-learning-foundations\",\"username\":\"Canvas Media Publish\",\"text\":\"$SLACK_MESSAGE\"}"
    ) || echo "Failed to send Slack message."
else
    echo "Would have sent a Slack message:"
    echo -e $SLACK_MESSAGE
fi
