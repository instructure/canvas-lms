def call(String branch, Integer commitHistory = 100 ) {
  _rebase(branch, commitHistory)
  if ( branch ==~ /dev\/.*/ ) {
    _rebase("master", commitHistory)
  }
}

def _rebase(String branch, Integer commitHistory) {
  git.fetch(branch, commitHistory)
  if (!git.hasCommonAncestor(branch)) {
    error "Error: your branch is over ${commitHistory} commits behind ${branch}, please rebase your branch manually."
  }
  if (!git.rebase(branch)) {
    error "Error: Rebase couldn't resolve changes automatically, please resolve these conflicts locally."
  }
}