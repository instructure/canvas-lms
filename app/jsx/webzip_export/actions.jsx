define([
  'redux-actions',
], (ReduxActions) => {
  const { createAction } = ReduxActions

  const keys = {
    CREATE_NEW_EXPORT: 'CREATE_NEW_EXPORT'
  }

  const actions = {
    createNewExport: createAction(keys.CREATE_NEW_EXPORT)
  }

  return {
    actions,
    keys
  }
})
