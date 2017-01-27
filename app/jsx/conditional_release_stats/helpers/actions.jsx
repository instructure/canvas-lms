import _ from 'underscore'

export function typeNameToFuncName (typeName) {
  const parts = typeName.split('_')
  return parts.map((part, i) => {
    if (i !== 0 && part.length) {
      return part.charAt(0).toUpperCase() + part.slice(1).toLowerCase()
    } else {
      return part.toLowerCase()
    }
  }).join('')
}

export function createAction (actionType) {
  const actionCreator = (payload) => ({
    type: actionType,
    payload,
  })

  actionCreator.type = actionType
  actionCreator.toString = () => actionType
  return actionCreator
}

export function createActions (actionDefs) {
  const actionTypes = {}
  const actions = {}

  actionDefs.forEach(actionDef => {
    const action = createAction(actionDef)
    const funcName = typeNameToFuncName(action.type)
    actions[funcName] = action
    actionTypes[action.type] = action.type
  })

  return { actionTypes, actions }
}
