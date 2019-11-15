
// TODO: until we get this into a shared library, 
//       i dont think we can hold flags in a variable

// TODO: maybe add a set of allowed flags so we know if we fat-finger something?

def hasFlag(name) {
  def script = """#!/bin/sh
    set -e
    message=`echo "\$GERRIT_CHANGE_COMMIT_MESSAGE" | base64 --decode`
    if echo "\$message" | grep -Eq '\\[$name\\]' ; then
      echo "found"
    fi
  """
  return sh(
    script: script,
    returnStdout: true
  ).trim() == 'found'
}

def getImageTagVersion() {
  // 'refs/changes/63/181863/8' -> '63.181863.8'
  return hasFlag('skip-docker-build') ? 'master' : "${env.GERRIT_REFSPEC}".minus('refs/changes/').replaceAll('/','.')
}

return this
