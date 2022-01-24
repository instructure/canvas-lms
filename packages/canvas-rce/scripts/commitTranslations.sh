CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

push() {
  OUTPUT=$( git push origin sync-translations-rce:refs/for/master%t=learning-materials,l=Verified+1 2>&1 )
  return $?
}

git checkout -B sync-translations-rce && \
  git add . && \
  git commit -m "[i18n] Update RCE translations." && \
  push && \
  git checkout $CURRENT_BRANCH

URL=$(echo $OUTPUT | grep -Eo 'https://[^ >]+')

aws --region us-east-1 sqs send-message \
  --no-cli-pager \
  --queue-url https://sqs.us-east-1.amazonaws.com/636161780776/slack-lambda \
  --message-body "{\"channel\":\"mat-bots\",\"username\":\"Package Translations\",\"text\":\"RCE translations have been updated. Publish to NPM needed! \\n $URL\"}"
