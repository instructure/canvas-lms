define [
  'Backbone'
  'underscore'
  'jquery'
  'jst/assignments/PostToSisSelector'
  'compiled/jquery/toggleAccessibly'
], (Backbone, _, $, template, toggleAccessibly) ->

  class PostToSisSelector extends Backbone.View

    template: template

    POST_TO_SIS              = '#assignment_post_to_sis'

    els: do ->
      els = {}
      els[POST_TO_SIS] = '$postToSis'
      els

    @optionProperty 'parentModel'
    @optionProperty 'nested'

    toJSON: =>
      postToSIS: @parentModel.postToSIS()
      nested: @nested
      prefix: 'assignment' if @nested
