define([
  "./createStore",
], function(createStore) {

  var UsersStore = createStore({
    getUrl() {
      return `/api/v1/accounts/${this.context.accountId}/users`;
    },

    normalizeParams(params) {
      var payload = {};
      if (params.search_term) payload.search_term = params.search_term;
      payload.include = ["last_login", "avatar_url", "email"];
      return payload;
    }
  });

  return UsersStore;
});
