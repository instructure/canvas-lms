define([
  'redux',
  './app',
  './create-store',
  './actions',
], ({ bindActionCreators }, App, createStore, { actions }) => {
  const CyoeStats = {
    init: (graphsRoot, detailsParent) => {
      const ENV = window.ENV
      if (ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED &&
          ENV.current_user_roles.indexOf('teacher') != -1 &&
          ENV.CONDITIONAL_RELEASE_ENV.rule != null)
      {
        const { assignment, jwt, stats_url } = ENV.CONDITIONAL_RELEASE_ENV

        const detailsRoot = document.createElement('div')
        detailsRoot.setAttribute('id', 'crs-details')
        detailsParent.appendChild(detailsRoot)

        assignment.submission_types = Array.isArray(assignment.submission_types) ? assignment.submission_types : [assignment.submission_types]
        const initState = {
          assignment,
          jwt,
          apiUrl: stats_url,
        }

        const store = createStore(initState)
        const boundActions = bindActionCreators(actions, store.dispatch)

        const app = new App(store, boundActions)

        app.renderGraphs(graphsRoot)
        app.renderDetails(detailsRoot)

        boundActions.loadInitialData()

        return app
      }
    },
  }

  return CyoeStats
})
