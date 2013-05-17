define [
  'jquery'
  'underscore'
  'Backbone'
  'jst/roles/accountRoles'
], ($, _, Backbone, template) -> 
  class AccountRolesView extends Backbone.View
    template: template
