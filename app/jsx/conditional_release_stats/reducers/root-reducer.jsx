define([
  'underscore',
  'redux',
  '../helpers/reducer',
  '../actions',
], (_, { combineReducers }, helper, { actionTypes }) => {
  const { handleActions, identity, getPayload } = helper

  const studentCache = handleActions({
    [actionTypes.ADD_STUDENT_TO_CACHE]: (state, action) => {
      const { studentId, data } = action.payload
      state[studentId] = {
        followOnAssignments: data.follow_on_assignments,
        triggerAssignment: data.trigger_assignment,
      }
      return state
    },
  }, {})

  const isInitialDataLoading = handleActions({
    [actionTypes.LOAD_INITIAL_DATA_START]: (state, action) => true,
    [actionTypes.LOAD_INITIAL_DATA_END]: (state, action) => false,
  }, false)

  const isStudentDetailsLoading = handleActions({
    [actionTypes.LOAD_STUDENT_DETAILS_START]: (state, action) => true,
    [actionTypes.LOAD_STUDENT_DETAILS_END]: (state, action) => false,
  }, false)

  const errors = handleActions({
    [actionTypes.SET_ERRORS]: (state, action) => {
      return [...action.payload, ...state]
    },
  }, [])

  const ranges = handleActions({
    [actionTypes.SET_INITIAL_DATA]: (state, action) => action.payload.ranges,
    [actionTypes.SET_SCORING_RANGES]: getPayload,
  }, [])

  const assignment = handleActions({
    [actionTypes.SET_ASSIGNMENT]: getPayload,
  }, {})

  const rule = handleActions({
    [actionTypes.SET_INITIAL_DATA]: (state, action) => action.payload.rule,
    [actionTypes.SET_RULE]: getPayload,
  }, { course_id: '', trigger_assignment: '' })

  const enrolled = handleActions({
    [actionTypes.SET_INITIAL_DATA]: (state, action) => action.payload.enrolled,
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
  }, { range: 0, student: null })

  return combineReducers({
    apiUrl: identity(),
    jwt: identity(),
    studentCache,
    isInitialDataLoading,
    isStudentDetailsLoading,
    errors,
    ranges,
    assignment,
    rule,
    enrolled,
    showDetails,
    selectedPath,
  })
})
