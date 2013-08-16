define [
  'jquery'
  'underscore'
  'Backbone'
], ($, _, Backbone) ->

  class Course extends Backbone.Model

    initialize: (@term) ->
      @selected = false # TODO: find a cleaner way to keep track of this runtime flag
      super

    # make useful custom attributes available to callers of toJSON()
    toJSON: ->
      $.extend Backbone.Model.prototype.toJSON.call(this),
        term: @term.get('name')
        selected: @selected

    addSectionTutorials: (newTutorials) ->
      # NOTE: does not currently check if course already has section tutorials
      if newTutorials.length > 0
        @set
          sectionTutorials: newTutorials
          key: "#{@get('key')}:::#{newTutorials.join(',').toLowerCase()}"
      this
