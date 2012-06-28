define [
  'Backbone',
  'i18n!dashboard'
  'underscore'
  'jst/quickStartBar/QuickStartBarView'
  'formToJSON'
], ({View, Model}, I18n, _, template) ->

  capitalize = (str) ->
    str.replace /\b[a-z]/g, (match) -> match.toUpperCase()

  class QuickStartBarModel extends Model
    defaults:
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

      @formViewsObj = _.reduce @options.formViews
      , (h, v) ->
        h[v.type] = v
        h
      , {}

      # not calling set() because I don't want the magic to run
      @model.attributes.modelName = @options.formViews[0].type

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
      @currentFormView?.teardown?()
      @currentFormView = @views[@modelName] or= do =>
        view = new @formViewsObj[@modelName]
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
      @$el.html(template formViews: @options.formViews)
      @cacheElements()
      @switchFormView()
      super

