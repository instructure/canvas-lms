define [
  'jquery'
  'underscore'
  'Backbone'
  'jst/roles/rolesOverrideIndex'
], ($, _, Backbone, template) ->
  class RolesOverrideIndexView extends Backbone.View

    template: template

    els:
      "#role_tabs": "$roleTabs"

    # Method Summary
    #   Enable tabs for account/course roles.
    # @api custom backbone override
    afterRender: ->
      @$roleTabs.tabs()

    toJSON: ->
      @options
