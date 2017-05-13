const loadingStates = ['queued', 'exporting', 'imports_queued']
const endStates = ['completed', 'exports_failed', 'imports_failed']
const states = [
  'void', 'unknown',
  ...loadingStates,
  ...endStates,
]

const migrationStates = states.reduce((map, state) =>
  Object.assign(map, {
    [state]: state,
  }), {})

migrationStates.states = states
migrationStates.isEndState = state => endStates.includes(state)
migrationStates.isLoadingState = state => loadingStates.includes(state)
migrationStates.getLoadingValue = state => loadingStates.indexOf(state) + 1
migrationStates.maxLoadingValue = loadingStates.length + 1

export default migrationStates
