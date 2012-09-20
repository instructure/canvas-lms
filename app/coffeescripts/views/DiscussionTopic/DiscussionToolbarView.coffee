define [
  'i18n!discussions'
  'Backbone'
  'underscore'
  'jqueryui/button'
], (I18n, {View}, _) ->

  ##
  # requires a MaterializedDiscussionTopic model
  class DiscussionToolbarView extends View

    els:
      '#discussion-search': '$searchInput'
      '#onlyUnread': '$unread'

    events:
      'keyup #discussion-search': 'filterBySearch'
      'change #onlyUnread': 'toggleUnread'

    initialize: ->
      @model.on 'change', @clearInputs

    afterRender: ->
      @$unread.button()

    filter: @::afterRender

    clearInputs: =>
      return if @model.hasFilter()
      @$searchInput.val ''
      @$unread.prop 'checked', false
      @$unread.button 'refresh'

    filterBySearch: _.debounce ->
      value = @$searchInput.val()
      value = null if value is ''
      @model.set 'query', value
    , 250

    toggleUnread: ->
      # setTimeout so the ui can update the button before the rest
      # do expensive stuff
      setTimeout =>
        @model.set 'unread', @$unread.prop 'checked'
      , 50

