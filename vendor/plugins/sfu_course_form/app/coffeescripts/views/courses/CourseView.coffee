define [
  'jquery'
  'underscore'
  'Backbone'
], ($, _, Backbone) ->

  class CourseView extends Backbone.View

    initialize: ->
      @model.on 'change', ( -> @render() ), this
      super

    tagName: 'li'

    template: _.template '<div><span class="term tag"><%= term %></span> <%= name %><%= number %> - <%= section %> <%= title %><% if (sectionTutorials.length) { %></div><div class="tutorial_sections">&mdash; includes tutorial sections: <%= sectionTutorials.join(", ") %></div><% } %>'

    render: ->
      this.$el.html @template @model.toJSON()
      this
