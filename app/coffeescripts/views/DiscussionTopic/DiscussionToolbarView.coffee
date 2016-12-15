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
      '#showDeleted': '$deleted'
      '.disableWhileFiltering': '$disableWhileFiltering'

    events:
      'keyup #discussion-search': 'filterBySearch'
      'change #onlyUnread': 'toggleUnread'
      'change #showDeleted': 'toggleDeleted'
      'click #collapseAll': 'collapseAll'
      'click #expandAll': 'expandAll'

    initialize: ->
      super
      @model.on 'change', @clearInputs

    afterRender: ->
      @$unread.button()
      @$deleted.button()

    filter: @::afterRender

    clearInputs: =>
      return if @model.hasFilter()
      @$searchInput.val ''
      @$unread.prop 'checked', false
      @$unread.button 'refresh'
      @maybeDisableFields()

    filterBySearch: _.debounce ->
      value = @$searchInput.val()
      value = null if value is ''
      @model.set 'query', value
      @maybeDisableFields()
    , 250

    toggleUnread: ->
      # setTimeout so the ui can update the button before the rest
      # do expensive stuff

      setTimeout =>
        @model.set 'unread', @$unread.prop 'checked'
        @maybeDisableFields()
      , 50

    toggleDeleted: ->
      @trigger 'showDeleted', @$deleted.prop('checked')

    collapseAll: ->
      @model.set 'collapsed', true
      @trigger 'collapseAll'

    expandAll: ->
      @model.set 'collapsed', false
      @trigger 'expandAll'

    maybeDisableFields: ->
      @$disableWhileFiltering.attr 'disabled', @model.hasFilter()

