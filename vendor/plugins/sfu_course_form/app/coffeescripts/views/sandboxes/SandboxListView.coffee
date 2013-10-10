define [
  'jquery'
  'underscore'
  'Backbone'
], ($, _, Backbone) ->

  class SandboxListView extends Backbone.View

    initialize: ->
      @collection.on 'request', ( -> this.$el.html '<p>Loading existing sandbox courses&hellip;</p>' ), this
      @collection.on 'sync', ( -> @render() ), this
      super

    tagName: 'div'

    template: _.template '<p>Here is a list of existing sandbox courses for <span class="username-display"><%= username %></span>:</p><ul></ul>'
    itemTemplate: _.template '<li><a href="/courses/<%= id %>" target="_blank"><%= name %></a></li>'
    emptyTemplate: _.template '<p><em>There are no existing sandboxes for <span class="username-display"><%= username %></span>.</em></p>'

    username: 'unknown'

    render: ->
      if @collection.length
        this.$el.empty()
        this.$el.append @template { username: @username }
        @collection.each @renderOne, this
      else
        @renderEmpty()
      this

    renderOne: (sandbox) ->
      console.log this.$el.children('ul')
      console.log sandbox.toJSON()
      this.$el.children('ul').append @itemTemplate sandbox.toJSON()

    renderEmpty: ->
      this.$el.html @emptyTemplate { username: @username }
