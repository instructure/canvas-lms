define [
  'jquery'
  'Backbone'
  'compiled/collections/AssignmentOverrideCollection'
  'jquery.ajaxJSON'
], ($, Backbone, AssignmentOverrideCollection) ->

  class Quiz extends Backbone.Model
    defaults:
      due_at: null
      unlock_at: null
      lock_at: null
      publishable: true

    initialize: (attributes, options = {}) ->
      @_baseUrl = options['baseUrl'] if options

      if attributes.assignment_overrides
        overrides = new AssignmentOverrideCollection(attributes.assignment_overrides)
        @set 'assignment_overrides', overrides, silent: true

    publish: =>
      if @get 'publishable'
        @set 'published', true
        $.ajaxJSON(@publishUrl(), 'POST', "quizzes": [@get("id")])

    unpublish: =>
      @set 'published', false
      $.ajaxJSON(@unpublishUrl(), 'POST', "quizzes": [@get("id")])

    publishUrl: ->
      "#{@_baseUrl}/publish"

    unpublishUrl: ->
      "#{@_baseUrl}/unpublish"