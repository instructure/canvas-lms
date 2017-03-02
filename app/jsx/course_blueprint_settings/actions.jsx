define([
  'redux-actions',
  './apiClient',
], ({ createActions }, api) => {
  const actionTypes = [
    'LOAD_COURSES_START', 'LOAD_COURSES_SUCCESS', 'LOAD_COURSES_FAIL',
    'LOAD_ASSOCIATIONS_START', 'LOAD_ASSOCIATIONS_SUCCESS', 'LOAD_ASSOCIATIONS_FAIL',
    'SAVE_ASSOCIATIONS_START', 'SAVE_ASSOCIATIONS_SUCCESS', 'SAVE_ASSOCIATIONS_FAIL',
    'ADD_COURSE_ASSOCIATIONS', 'UNDO_ADD_COURSE_ASSOCIATIONS',
    'REMOVE_COURSE_ASSOCIATIONS', 'UNDO_REMOVE_COURSE_ASSOCIATIONS',
  ]
  const actions = createActions(...actionTypes)

  actions.cancel = () => (dispatch, getState) => {
    const referrer = document.referrer
    if (referrer.split('/')[2] !== location.host || referrer.includes('/login')) {
      location.replace(`/courses/${getState().course.id}`)
    } else {
      location.replace(referrer)
    }
  }

  actions.addAssociations = associations => (dispatch, getState) => {
    const state = getState()
    const existing = state.existingAssociations
    const toAdd = []
    const toUndo = []

    associations.forEach((courseId) => {
      if (existing.find(course => course.id === courseId)) {
        toUndo.push(courseId)
      } else {
        toAdd.push(courseId)
      }
    })

    if (toAdd.length) {
      const courses = state.courses.concat(state.existingAssociations)
      dispatch(actions.addCourseAssociations(courses.filter(c => toAdd.includes(c.id))))
    }

    if (toUndo.length) {
      dispatch(actions.undoRemoveCourseAssociations(toUndo))
    }
  }

  actions.removeAssociations = associations => (dispatch, getState) => {
    const existing = getState().existingAssociations
    const toRm = []
    const toUndo = []

    associations.forEach((courseId) => {
      if (existing.find(course => course.id === courseId)) {
        toRm.push(courseId)
      } else {
        toUndo.push(courseId)
      }
    })

    if (toRm.length) {
      dispatch(actions.removeCourseAssociations(toRm))
    }

    if (toUndo.length) {
      dispatch(actions.undoAddCourseAssociations(toUndo))
    }
  }

  actions.loadCourses = filters => (dispatch, getState) => {
    dispatch(actions.loadCoursesStart())
    api.getCourses(getState(), filters)
      .then(res => dispatch(actions.loadCoursesSuccess(res.data)))
      .catch(err => dispatch(actions.loadCoursesFail(err)))
  }

  actions.loadAssociations = () => (dispatch, getState) => {
    dispatch(actions.loadAssociationsStart())
    api.getAssociations(getState())
      .then((res) => {
        const data = res.data.map(course =>
          Object.assign({}, course, {
            term: {
              id: '0',
              name: course.term_name,
            },
            term_name: undefined,
          }))
        dispatch(actions.loadAssociationsSuccess(data))
      })
      .catch(err => dispatch(actions.loadAssociationsFail(err)))
  }

  actions.saveAssociations = () => (dispatch, getState) => {
    dispatch(actions.saveAssociationsStart())
    const state = getState()
    api.saveAssociations(state)
      .then(() => dispatch(actions.saveAssociationsSuccess({ added: state.addedAssociations, removed: state.removedAssociations })))
      .catch(err => dispatch(actions.saveAssociationsFail(err)))
  }

  // map action types to props on the actions object
  actions.actionTypes = actionTypes.reduce((types, actionType) =>
    Object.assign(types, { [actionType]: actionType }), {})

  return actions
})
