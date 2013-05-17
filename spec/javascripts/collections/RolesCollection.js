(function() {

  define(['Backbone', 'underscore', 'compiled/models/Role', 'compiled/collections/RolesCollection', 'compiled/util/BaseRoleTypes'], function(Backbone, _, Role, RolesCollection, BASE_ROLE_TYPES) {
    module('RolesCollection', {
      setup: function() {
        return this.account_id = 2;
      },
      teardown: function() {
        return this.account_id = null;
      }
    });
    return test("generate the correct url for a collection of roles", 1, function() {
      var roles_collection;
      roles_collection = new RolesCollection;
      return equal(roles_collection.url(), "/accounts/" + this.account_id + "/roles", "roles collection url");
    });
  });

}).call(this);
