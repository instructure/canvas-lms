define([
  'redux',
  './app',
  './create-store',
  './actions',
], ({ bindActionCreators }, App, createStore, { actions }) => {
  const CyoeStats = {
    init: (graphsRoot, detailsRoot, assignment, jwt, apiUrl) => {
      assignment.submission_types = Array.isArray(assignment.submission_types) ? assignment.submission_types : [assignment.submission_types]
      const initState = {
        assignment,
        jwt,
        apiUrl,
      }

      const store = createStore(initState)
      const boundActions = bindActionCreators(actions, store.dispatch)

      const app = new App(store, boundActions)

      app.renderGraphs(graphsRoot)
      app.renderDetails(detailsRoot)

      boundActions.loadInitialData()
    },
  }

  return CyoeStats
})
