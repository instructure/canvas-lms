define [
  'i18n!groups'
  'jquery'
  'underscore'
  'Backbone'
  'compiled/views/CollectionView'
  'compiled/views/groups/manage/GroupCategoryView'
  'compiled/views/groups/manage/GroupCategoryCreateView'
  'compiled/models/GroupCategory'
  'jst/groups/manage/groupCategories'
  'jst/groups/manage/groupCategoryTab'
  'jqueryui/tabs'
], (I18n, $, _, {View}, CollectionView, GroupCategoryView, GroupCategoryCreateView, GroupCategory, groupCategoriesTemplate, tabTemplate) ->

  class GroupCategoriesView extends CollectionView

    template: groupCategoriesTemplate

    className: 'group_categories_area'

    els: _.extend {},
      CollectionView::els
      '#group_categories_tabs': '$tabs'
      'li.static': '$static'
      '#add-group-set': '$addGroupSetButton'
      '.empty-groupset-instructions': '$emptyInstructions'

    events:
      'click #add-group-set': 'addGroupSet'
      'tabsactivate #group_categories_tabs': 'activatedTab'

    itemView: View.extend
      tagName: 'li'
      template: -> tabTemplate _.extend(@model.present(), id: @model.id ? @model.cid)


    render: ->
      super
      @reorder() if @collection.length > 1
      @refreshTabs()
      @loadTabFromUrl()

    refreshTabs: ->
      if @collection.length > 0
        @$tabs.find('ul.ui-tabs-nav li.static').remove()
        @$tabs.find('ul.ui-tabs-nav').prepend(@$static)
      # setup the tabs
      if @$tabs.data("tabs")
        @$tabs.tabs("refresh").show()
      else
        @$tabs.tabs({cookie: {}}).show()

      @$tabs.tabs
        beforeActivate: (event, ui) ->
          !ui.newTab.hasClass('static')

      # hide/show the instruction text
      if @collection.length > 0
        @$emptyInstructions.hide()
      else
        @$emptyInstructions.show()
        # hide the emtpy tab set which may have borders that would otherwise show
        @$tabs.hide()
      @$tabs.find('li.static a').unbind()
      @$tabs.on 'keydown', 'li.static', (event) ->
        event.stopPropagation()
        if event.keyCode == 13 or event.keyCode == 32
          window.location.href = $(this).find('a').attr('href')

    loadTabFromUrl: ->
      if location.hash == "#new"
        @addGroupSet()
      else
        id = location.hash.split('-')[1]
        if id?
          model = @collection.get(id)
          if model
            @$tabs.tabs active: @tabOffsetOfModel(model)


    tabOffsetOfModel: (model) ->
      index = @collection.indexOf(model)
      numStatic = @$static.length
      index + numStatic

    createItemView: (model) ->
      # create and add tab panel
      panelId = "tab-#{model.id ? model.cid}"
      $panel = $('<div/>').addClass('tab-panel').attr('id', panelId).data('loaded', false).data('model', model)
      @$tabs.append($panel)
      # If this is the first panel, load the contents
      if @$tabs.find('.tab-panel').length == 1
        @loadPanelView($panel, model)
      # create the <li> tab view
      view = super
      view.listenTo model, 'change', => # e.g. change name
        view.render()
        @reorder()
        @refreshTabs()
      view

    renderItem: ->
      super
      @refreshTabs()

    removeItem: (model) ->
      super
      # remove the linked panel and refresh the tabs
      model.itemView.remove()
      model.panelView?.remove()
      @refreshTabs()

    addGroupSet: (e) ->
      e.preventDefault() if e?
      @createView ?= new GroupCategoryCreateView
        collection: @collection
        trigger: @$addGroupSetButton
      cat = new GroupCategory
      cat.once 'sync', =>
        window.location.hash = "tab-#{cat.id}"
        @collection.add(cat)
        @reorder()
        @refreshTabs()
        @$tabs.tabs active: @tabOffsetOfModel(cat)
        cat.set "create_group_count", null
      @createView.model = cat
      @createView.open()

    activatedTab: (event, ui) ->
      $panel = ui.newPanel
      @loadPanelView($panel)

    loadPanelView: ($panel) ->
      # there is a bug here where we load the first tab, then immediately load the tab from the hash
      if !$panel.data('loaded')
        model = $panel.data('model')
        categoryView = new GroupCategoryView model: model
        categoryView.setElement($panel)
        categoryView.render()
        # return the created tab <li> view
        model.panelView = $panel
        # store now loaded
        $panel.data('loaded', true)
      $panel

    toJSON: ->
      json = super
      json.ENV=ENV
      context = ENV.context_asset_string.split('_')
      json.context = context[0]
      json.isCourse = json.context == "course"
      json.context_id = context[1]
      json

