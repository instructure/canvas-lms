CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

push() {
  if [ ! -z "$SUPPRESS_PUSH" ]; then
    #
    # You can use with SUPPRESS_PUSH=1 when testing locally, to avoid
    # errors about not being able to auto-submit
    #
    echo "Would have pushed a PS to Gerrit"
    return 0
  fi

  OUTPUT=$( git push origin sync-translations-media:refs/for/master%submit,t=learning-materials,l=Verified+1 2>&1 )
  return $?
}

git checkout -q -B sync-translations-media && \
  git add -A src && \
  git commit -m "[i18n] Update canvas-media translations." && \
  push

echo $OUTPUT

git checkout -q $CURRENT_BRANCH

if [ ! -z "$OUTPUT" ]; then
  URL=$(echo $OUTPUT | grep -Eo 'https://[^ >]+')

  SLACK_MESSAGE="canvas-media translations have been updated. Publish to NPM needed! \\n $URL"

  if [ ! -z "$SUPPRESS_SLACK" ]; then
    #
    # You can use with SUPPRESS_SLACK=1 when testing locally, to avoid
    # making noise in Slack
    #
    echo "Would have sent a Slack message:"
    echo $SLACK_MESSAGE
  else
    (
      aws --region us-east-1 sqs send-message \
        --queue-url https://sqs.us-east-1.amazonaws.com/636161780776/slack-lambda \
        --message-body "{\"channel\":\"#learning-foundations\",\"username\":\"Package Translations\",\"text\":\"$SLACK_MESSAGE\"}"
    ) || echo "Failed to send Slack message."
  fi
fi
