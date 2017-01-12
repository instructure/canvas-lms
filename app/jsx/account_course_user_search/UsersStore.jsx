define([
  "underscore",
  "./createStore"
], function (_, createStore) {

  var UsersStore = createStore({
    getUrl() {
      return `/api/v1/accounts/${this.context.accountId}/users`;
    },

    normalizeParams(params) {
      var payload = {};
      if (params.search_term) {
        payload.search_term = params.search_term;
      } else {
        payload = _.extend({}, params);
      }
      payload.include = ["last_login", "avatar_url", "email", "time_zone"];
      return payload;
    }
  });

  return UsersStore;
});
