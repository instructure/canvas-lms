define [
  'Backbone',
  'i18n!dashboard'
  'compiled/views/QuickStartBar/allViews'
  'jst/quickStartBar/QuickStartBarView'
  'formToJSON'
], ({View, Model}, I18n, allViews, template) ->

	capitalize = (str) ->
    str.replace /\b[a-z]/g, (match) -> match.toUpperCase()

  class QuickStartBarModel extends Model
    defaults:
      modelName: 'assignment'
      expanded: false

  ##
  # Controls the activity feed and the panel that filters it
  class QuickStartBarView extends View

    events:
      'click .nav a': 'onNavClick'
      'focus .expander': 'onExpandClick'

    initialize: ->
      @model or= new QuickStartBarModel
      @model.on 'change:modelName', @switchFormView
      @model.on 'change:expanded', @toggleExpanded
      @models = {}

    onSaveSuccess: (model) =>
      @switchFormView()
      @trigger 'save'

    onSaveFail: (model) =>
      @switchFormView()
      @trigger 'saveFail'

    onNavClick: (event) ->
      event.preventDefault()
      type = $(event.currentTarget).data 'type'
      @model.set 'modelName', type

    onExpandClick: (event) ->
      @model.set 'expanded', true

    switchFormView: =>
      @$el.removeClass @modelName if @modelName
      @modelName = @model.get 'modelName'
      @$el.addClass @modelName
      viewName = capitalize(@modelName) + 'View'
      @currentFormView?.teardown?()
      @currentFormView = @views[viewName] or= do =>
        view = new allViews[viewName]
        view.on 'save', @onSaveSuccess
        view.on 'saveFail', @onSaveFail
      @currentFormView.render()
      @$newItemFormContainer.empty().append @currentFormView.el
      @model.set 'expanded', false
      @updateActiveTab @modelName

    toggleExpanded: (model, expanded) =>
      @$el.toggleClass 'expanded', expanded
      @$el.toggleClass 'not-expanded', not expanded

    updateActiveTab: (modelName) ->
      @$('.nav a').each (index, tab) ->
        $tab = $ tab
        if $tab.is "[data-type=#{modelName}]"
          $tab.addClass 'active'
        else
          $tab.removeClass 'active'

    cacheElements: ->
      @$newItemFormContainer = $ '.newItemFormContainer'

    render: ->
      @$el.html template()
      @cacheElements()
      @switchFormView()
      super

