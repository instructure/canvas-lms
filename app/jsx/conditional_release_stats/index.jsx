define([
  'underscore',
  'redux',
  './app',
  './create-store',
  './actions',
], (_, { bindActionCreators }, App, createStore, { actions }) => {
  const CyoeStats = {
    init: (graphsRoot, detailsRoot, assignment, jwt, apiUrl) => {
      const initState = {
        assignment,
        jwt,
        apiUrl,
      }

      const store = createStore(initState)
      const boundActions = bindActionCreators(actions, store.dispatch)

      const app = new App(boundActions)

      app.renderGraphs(store, graphsRoot)
      app.renderDetails(store, detailsRoot)

      boundActions.loadData()
    },
  }

  return CyoeStats
})
