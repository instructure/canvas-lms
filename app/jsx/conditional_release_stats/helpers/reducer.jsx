define([
  'underscore',
], (_) => {
  const reducersHelper = {
    handleActions: (actionHandler, def) => {
      return (state, action) => {
        state = state === undefined ? def : state

        if (actionHandler[action.type]) {
          let stateCopy = state
          if (_.isObject(state)) {
            stateCopy = _.extend({}, state)
          } else if (Array.isArray(state)) {
            stateCopy = state.slice()
          }

          return actionHandler[action.type](stateCopy, action)
        } else {
          return state
        }
      }
    },

    getPayload: (state, action) => action.payload,

    identity: (def = '') => (s, a) => s === undefined ? def : s,
  }

  return reducersHelper
})
