define([
  './cyoe-api',
  './helpers/actions',
], (cyoeClient, { createActions }) => {
  const actionDefs = [
    'SET_INITIAL_DATA',
    'SET_SCORING_RANGES',
    'SET_RULE',
    'SET_ENROLLED',
    'SET_ASSIGNMENT',
    'SET_ERRORS',
    'SET_STUDENT_DETAILS',
    'SELECT_RANGE',
    'ADD_STUDENT_TO_CACHE',
    'SELECT_STUDENT',
    'OPEN_SIDEBAR',
    'CLOSE_SIDEBAR',
    'LOAD_INITIAL_DATA_START',
    'LOAD_INITIAL_DATA_END',
    'LOAD_STUDENT_DETAILS_START',
    'LOAD_STUDENT_DETAILS_END',
  ]

  const { actions, actionTypes } = createActions(actionDefs)

  actions.loadInitialData = (assignment) => {
    return (dispatch, getState) => {
      dispatch(actions.loadInitialDataStart())

      cyoeClient.loadInitialData(getState())
        .then(data => {
          dispatch(actions.setInitialData(data))
          dispatch(actions.loadInitialDataEnd())
        })
        .catch(errors => {
          dispatch(actions.setErrors(errors))
          dispatch(actions.loadInitialDataEnd())
        })
    }
  }

  actions.loadStudent = (studentId) => {
    return (dispatch, getState) => {
      dispatch(actions.loadStudentDetailsStart())

      cyoeClient.loadStudent(getState(), studentId)
        .then(data => {
          dispatch(actions.addStudentToCache({ studentId, data }))
          dispatch(actions.loadStudentDetailsEnd())
        })
        .catch(errors => {
          dispatch(actions.loadStudentDetailsEnd())
          dispatch(actions.setErrors(errors))
        })
    }
  }

  actions.selectStudent = (studentIndex) => {
    return (dispatch, getState) => {
      dispatch({ type: actionTypes.SELECT_STUDENT, payload: studentIndex })

      const {
        studentCache,
        ranges,
        selectedPath,
      } = getState()

      const student = ranges[selectedPath.range].students[studentIndex]

      if (student && !studentCache[student.user.id.toString()]) {
        dispatch(actions.loadStudent(student.user.id.toString()))
      }
    }
  }

  return { actions, actionTypes }
})
