define([
  'redux-actions',
  './apiClient',
], ({ createActions }, api) => {
  const actionTypes = ['LOAD_COURSES_START', 'LOAD_COURSES_SUCCESS', 'LOAD_COURSES_FAIL']
  const actions = createActions(...actionTypes)

  actions.loadCourses = filters => (dispatch, getState) => {
    dispatch(actions.loadCoursesStart())
    api.getCourses(getState(), filters)
      .then(res => dispatch(actions.loadCoursesSuccess(res.data)))
      .catch(err => dispatch(actions.loadCoursesFail(err)))
  }

  actions.actionTypes = actionTypes.reduce((types, actionType) =>
    Object.assign(types, { [actionType]: actionType }), {})

  return actions
})
