define([
  './createStore',
], (createStore) => {
  const UsersStore = createStore({
    getUrl () {
      return `/api/v1/accounts/${this.context.accountId}/users`;
    },

    normalizeParams (params) {
      let payload = {}
      if (params.search_term) {
        payload.search_term = params.search_term
      } else {
        payload = Object.assign({}, params)
      }
      payload.include = ['last_login', 'avatar_url', 'email', 'time_zone']
      return payload
    }
  })

  return UsersStore
})
