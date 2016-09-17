define([
  'react',
  'react-dom',
  'jsx/cyoe_assignment_sidebar/components/conditional-stats-component',
  'jsx/cyoe_assignment_sidebar/store/configure-store',
  'jsx/cyoe_assignment_sidebar/actions/conditional-actions',
  'jsx/cyoe_assignment_sidebar/cyoe-api',
], (React, ReactDOM, ConditionalBarsBreakdown, configureStore, Actions, cyoeClient) => {

  const createConditionalBreakdown = (elementName, assignment, jwt, url) => {
    const domElement = document.getElementById(elementName)
    const initState = cyoeClient.getStats(assignment.id, jwt, url).then((result) => {
      const store = configureStore(result)
      const state = store.getState()
      state.assignment = assignment

      const props = {
        state
      }

      const ConditionalBreakdownComponent = React.createElement( ConditionalBarsBreakdown, props )

      store.subscribe(() => {
        ReactDOM.render(ConditionalBreakdownComponent, domElement)
      })

      store.dispatch(Actions.setScoringRanges(state.ranges))

    }, (err) => {
       console.warn('Mastery Paths Breakdown did not render correctly with Error: ', err)
    });
  }

  return createConditionalBreakdown
});