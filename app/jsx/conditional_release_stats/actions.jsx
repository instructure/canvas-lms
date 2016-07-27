define([
  './cyoe-api',
  './helpers/actions',
], (cyoeClient, { createActions }) => {
  const actionDefs = [
    'SET_SCORING_RANGES',
    'SET_RULE',
    'SET_ENROLLED',
    'SET_ASSIGNMENT',
    'SET_ERRORS',
    'SELECT_RANGE',
    'SELECT_STUDENT',
    'OPEN_SIDEBAR',
    'CLOSE_SIDEBAR',
    'LOAD_START',
    'LOAD_END',
  ]

  const { actions, actionTypes } = createActions(actionDefs)

  actions.loadData = (assignment) => {
    return (dispatch, getState) => {
      dispatch(actions.loadStart())

      cyoeClient.loadInitialData(getState())
        .then(data => {
          dispatch(actions.setScoringRanges(data.ranges))
          dispatch(actions.setRule(data.rule))
          dispatch(actions.setEnrolled(data.enrolled))
          dispatch(actions.loadEnd())
        }, errors => {
          dispatch(actions.setErrors(errors))
          dispatch(actions.loadEnd())
        })
    }
  }

  return { actions, actionTypes }
})
