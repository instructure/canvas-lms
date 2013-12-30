define [
  'i18n!groups'
  'underscore'
  'Backbone'
  'compiled/views/CollectionView'
  'compiled/views/groups/manage/GroupCategoryView'
  'compiled/views/groups/manage/GroupCategoryCreateView'
  'compiled/models/GroupCategory'
  'jst/groups/manage/groupCategories'
  'jst/groups/manage/groupCategoryTab'
  'jqueryui/tabs'
], (I18n, _, {View}, CollectionView, GroupCategoryView, GroupCategoryCreateView, GroupCategory, groupCategoriesTemplate, tabTemplate) ->

  class GroupCategoriesView extends CollectionView

    template: groupCategoriesTemplate

    className: 'group_categories_area'

    els: _.extend {},
      CollectionView::els
      '#group_categories_tabs': '$tabs'
      '#add-group-set': '$addGroupSetButton'
      '.empty-groupset-instructions': '$emptyInstructions'

    events:
      'click #add-group-set': 'addGroupSet'
      'tabsactivate #group_categories_tabs': 'activatedTab'

    itemView: View.extend
      tagName: 'li'
      template: tabTemplate

    refreshTabs: ->
      # setup the tabs
      if @$tabs.data("tabs")
        @$tabs.tabs("refresh").show()
      else
        @$tabs.tabs({cookie: {}}).show()

      # hide/show the instruction text
      if @collection.length > 0
        @$emptyInstructions.hide()
      else
        @$emptyInstructions.show()
        # hide the emtpy tab set which may have borders that would otherwise show
        @$tabs.hide()

    createItemView: (model) ->
      # create and add tab panel
      panelId = "tab-#{model.id}"
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
        @$tabs.tabs active: @collection.indexOf(model)
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
      e.preventDefault()
      @createView ?= new GroupCategoryCreateView
        collection: @collection
        trigger: @$addGroupSetButton
      cat = new GroupCategory
      cat.once 'sync', =>
        @collection.add(cat)
        @$tabs.tabs active: @collection.indexOf(cat)
      @createView.model = cat
      @createView.open()

    activatedTab: (event, ui) ->
      $panel = ui.newPanel
      @loadPanelView($panel)

    loadPanelView: ($panel) ->
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
