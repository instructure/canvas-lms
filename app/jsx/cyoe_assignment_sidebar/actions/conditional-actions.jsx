define ([
  'jsx/cyoe_assignment_sidebar/cyoe-api',
], (cyoeClient) => {

  const ConditionalActions = {
    SET_SCORING_RANGES: 'SET_SCORING_RANGES',
    SET_BAR_AT_INDEX: 'SET_BAR_AT_INDEX',
    SET_RULE: 'SET_RULE',
    SET_ENROLLED: 'SET_ENROLLED',
    SET_ERRORS: 'SET_ERRORS',
    SET_ASSIGNMENT: 'SET_ASSIGNMENT',
    API_UPDATE_STATE: 'API_UPDATE_STATE',
    OPEN_SIDEBAR: 'OPEN_SIDEBAR',
    CLOSE_SIDEBAR: 'CLOSE_SIDEBAR'
  };

  ConditionalActions.setScoringRanges = (newRanges) => {
    return {
      type: ConditionalActions.SET_SCORING_RANGES,
      payload: newRanges
    };
  }

  ConditionalActions.setBarAtIndex = (index, bar) => {
    return {
      type: ConditionalActions.SET_BAR_AT_INDEX,
      payload: {
        index,
        bar,
      }
    };
  }

  ConditionalActions.setErrors = (errors) => {
    return {
      type: ConditionalActions.SET_ERRORS,
      payload: errors
    };
  }

  ConditionalActions.setEnrolled = (enrolled) => {
    return {
      type: ConditionalActions.SET_ENROLLED,
      payload: enrolled
    };
  }

  ConditionalActions.setRule = (rule) => {
    return {
      type: ConditionalActions.SET_RULE,
      payload: rule
    };
  }

  ConditionalActions.setAssignment = (assignment) => {
    return {
      type: ConditionalActions.SET_ASSIGNMENT,
      payload: assignment
    };
  }

  ConditionalActions.openSidebar = (index) => {
    return {
      type: ConditionalActions.OPEN_SIDEBAR,
      payload: index
    };
  }

  ConditionalActions.closeSidebar = () => {
    return {
      type: ConditionalActions.CLOSE_SIDEBAR,
    };
  }

  ConditionalActions.apiUpdateState = (aid, jwt, url) => {
    return (dispatch, getState) => {
      cyoeClient.getStats(aid, jwt, url).then((state) => {
        dispatch(ConditionalActions.setScoringRanges(state.ranges))
        dispatch(ConditionalActions.setRule(state.rule))
        dispatch(ConditionalActions.setEnrolled(state.enrolled))
        dispatch(ConditionalActions.setAssignment(state.assignment));
      });
    };
  }

  return ConditionalActions;
});
