define [
  'jquery'
  'underscore'
  'Backbone'
  'sfu_course_form/compiled/views/terms/TermView'
], ($, _, Backbone, TermView) ->

  class TermListView extends Backbone.View

    tagName: 'ul'

    render: ->
      if @collection.length
        @collection.each @renderOne, this
      else
        this.$el.html('<li>No terms</li>')
      this

    renderOne: (term) ->
      termView = new TermView({model: term})
      this.$el.append termView.render().el
