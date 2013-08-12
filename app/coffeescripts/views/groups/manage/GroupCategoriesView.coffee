define [
  'i18n!groups'
  'underscore'
  'Backbone'
  'compiled/views/CollectionView'
  'compiled/views/groups/manage/GroupCategoryView'
  'jst/groups/manage/groupCategories'
  'jst/groups/manage/groupCategoryTab'
  'jqueryui/tabs'
], (I18n, _, {View}, CollectionView, GroupCategoryView, groupCategoriesTemplate, tabTemplate) ->

  class GroupCategoriesView extends CollectionView

    template: groupCategoriesTemplate

    className: 'group_categories_area'

    els: _.extend {},
      CollectionView::els,
      '#group_categories_tabs': '$tabs'
      '#add-group-set': '$addGroupSetButton'

    events:
      'click #add-group-set': 'addGroupSet'
      'tabsactivate #group_categories_tabs': 'activatedTab'

    itemView: View.extend
      tagName: 'li'
      template: tabTemplate

    setupTabs: ->
      if !@$tabs.data("tabs")
        @$tabs.tabs({cookie: {}}).show()

    refreshTabs: ->
      if @$tabs.data("tabs")
        @$tabs.tabs("refresh").show()
      else
        @setupTabs()

    createItemView: (model) ->
      # create and add tab panel
      panelId = "tab-#{model.id}"
      $panel = $('<div/>').addClass('tab-panel').attr('id', panelId).data('loaded', false).data('model', model)
      @$tabs.append($panel)
      # If this is the first panel, load the contents
      if @$tabs.find('.tab-panel').length == 1
        @loadPanelView($panel, model)
      # create the <li> tab view
      super

    renderItem: ->
      super
      @refreshTabs()

    removeItem: (model)->
      super
      # remove the linked panel and refresh the tabs
      model.panelView.remove()
      @refreshTabs()

    addGroupSet: (e)->
      e.preventDefault()
      alert('will add a group set')

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
