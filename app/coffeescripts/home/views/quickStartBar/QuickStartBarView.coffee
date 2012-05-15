define [
  'Backbone',
  'i18n!dashboard'
  'compiled/home/views/quickStartBar/allViews'
], ({View, Model}, I18n, views) ->

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

    onNavClick: (event) ->
      event.preventDefault()
      type = $(event.target).data 'type'
      @model.set 'modelName', type

    onExpandClick: (event) ->
      @model.set 'expanded', true

    switchFormView: =>
      modelName = @model.get('modelName')
      viewName = capitalize(modelName) + 'View'
      @currentFormView?.teardown?()
      @currentFormView = @views[viewName] or= new views[viewName]
      @currentFormView.render()
      @$newItemFormContainer.empty().append @currentFormView.el
      @model.set 'expanded', false
      @updateActiveTab modelName

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
      @$el.html """
        <div class="row-fluid pick-an-item border border-b box-shadow">
          <div class="span2">
            <span class="new-text">#{I18n.t 'new', 'New'}:</span>
          </div>
          <div class=span10>
            <ul class="nav nav-tabs">
              <li><a data-type="assignment" href="#"><i class="icon-assignment"></i>#{I18n.t 'assignment', 'Assignment'}</a></li>
              <li><a data-type="discussion" href="#"><i class="icon-discussion"></i>#{I18n.t 'discussion', 'Discussion'}</a></li>
              <li><a data-type="announcement" href="#"><i class="icon-announcement"></i>#{I18n.t 'announcement', 'Announcement'}</a></li>
              <li><a data-type="message" href="#"><i class="icon-message"></i>#{I18n.t 'message', 'Message'}</a></li>
              <li><a data-type="pin" href="#"><i class="icon-pin"></i>#{I18n.t 'pin', 'Pin'}</a></li>
            </ul>
          </div>
        </div>

        <div class="v-gutter">
          <div class="container-fluid message">
            <div class="image-block control-group">
              <div class="image-block-image">
                <i class="item-type-image icon-large-assignment"></i>
              </div>

              <div class="newItemFormContainer image-block-content triangle-box"></div>

            </div>
          </div>
        </div>
      """
      @cacheElements()
      # get the right form in there after render
      @switchFormView()
      super

