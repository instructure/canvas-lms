define([
  'redux',
  'redux-actions',
  './actions',
  '../shared/helpers/assignment-categories',
], ({ combineReducers }, { handleActions }, actions, Categories) => {
  return combineReducers({
    error: handleActions({
      [actions.SET_ERROR]: (state, action) => action.payload,
    }, ''),
    options: handleActions({
      [actions.SET_OPTIONS]: (state, action) => {
        const options = action.payload
        options.forEach(option => {
          option.assignments.forEach(assg => {
            if (assg.due_at) assg.due_at = new Date(assg.due_at)
            if (!Array.isArray(assg.submission_types)) assg.submission_types = [assg.submission_types]
            assg.category = Categories.getCategory(assg)
          })
        })
        return options
      },
    }, []),
    selectedOption: handleActions({
      [actions.SELECT_OPTION]: (state, action) => action.payload,
    }, null),
    courseId: (state = '', action) => state,
    moduleId: (state = '', action) => state,
    itemId: (state = '', action) => state,
  })
})
