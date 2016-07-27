define([
  'underscore',
  'redux',
  '../helpers/reducer',
  '../actions',
], (_, { combineReducers }, helper, { actionTypes }) => {
  const { handleActions, identity, getPayload } = helper

  const isLoading = handleActions({
    [actionTypes.LOAD_START]: (state, action) => true,
    [actionTypes.LOAD_END]: (state, action) => false,
  }, false)

  const errors = handleActions({
    [actionTypes.SET_ERRORS]: (state, action) => {
      return [...action.payload, ...state]
    },
  }, [])

  const ranges = handleActions({
    [actionTypes.SET_SCORING_RANGES]: getPayload,
  }, [])

  const assignment = handleActions({
    [actionTypes.SET_ASSIGNMENT]: getPayload,
  }, {})

  const rule = handleActions({
    [actionTypes.SET_RULE]: getPayload,
  }, {})

  const enrolled = handleActions({
    [actionTypes.SET_ENROLLED]: getPayload,
  }, 0)

  const showDetails = handleActions({
    [actionTypes.OPEN_SIDEBAR]: (state, action) => true,
    [actionTypes.CLOSE_SIDEBAR]: (state, action) => false,
    [actionTypes.SELECT_RANGE]: (state, action) => action.payload !== null,
  }, false)

  const selectedPath = handleActions({
    [actionTypes.SELECT_RANGE]: (state, action) => {
      state.range = action.payload
      return state
    },
    [actionTypes.SELECT_STUDENT]: (state, action) => {
      state.student = action.payload
      return state
    },
    [actionTypes.CLOSE_SIDEBAR]: (state, action) => {
      state.student = null
      return state
    },
  }, { range: 0 })

  return combineReducers({
    apiUrl: identity(),
    jwt: identity(),
    isLoading,
    errors,
    ranges,
    assignment,
    rule,
    enrolled,
    showDetails,
    selectedPath,
  })
})
