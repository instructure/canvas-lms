define [
  'jquery'
  'underscore'
  'Backbone'
  'jst/roles/RolesCollectionView'
], ($, _, Backbone, template) ->
  class RolesCollectionView extends Backbone.View
    template: template

    els:
      ".add_role_link": "$addRoleLink"

    @optionProperty 'newRoleView'

    afterRender: ->
      @newRoleView.setTrigger @$addRoleLink