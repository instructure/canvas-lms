define [
  'jquery'
  'compiled/views/groups/manage/GroupCategoriesView'
  'compiled/collections/GroupCategoryCollection'
  'compiled/models/GroupCategory'
  'helpers/fakeENV'
], ($, GroupCategoriesView, GroupCategoryCollection, GroupCategory, fakeENV) ->
  clock = null
  view = null
  categories = null
  wrapper = null
  sanbox = null

  module 'GroupCategoriesView',
    setup: ->
      fakeENV.setup()
      ENV.group_categories_url = '/api/v1/courses/1/group_categories'
      clock = sinon.useFakeTimers()
      categories = new GroupCategoryCollection [
        {id: 1, name: "group set 1"}
        {id: 2, name: "group set 2"}
      ]
      @stub(categories, "fetch").returns([])
      view = new GroupCategoriesView
        collection: categories
      view.render()
      wrapper = document.getElementById("fixtures")
      wrapper.innerHTML = ""
      view.$el.appendTo($("#fixtures"))

    teardown: ->
      fakeENV.teardown()
      clock.restore()
      view.remove()
      wrapper.innerHTML = ""

  test 'render tab and panel elements', ->
    # find the tabs
    equal view.$el.find('.collectionViewItems > li').length, 2
    # find the panels
    equal view.$el.find('#tab-1').length, 1
    equal view.$el.find('#tab-2').length, 1

  test 'adding new GroupCategory should display new tab and panel', ->
    categories.add( new GroupCategory({id: 3, name: 'Newly Added'}))
    equal view.$el.find('.collectionViewItems > li').length, 3
    equal view.$el.find('#tab-3').length, 1

  test 'removing GroupCategory should remove tab and panel', ->
    categories.remove categories.models[0]
    equal view.$el.find('.collectionViewItems > li').length, 1
    equal view.$el.find('#tab-1').length, 0
    categories.remove categories.models[0]
    equal view.$el.find('.collectionViewItems > li').length, 0
    equal view.$el.find('#tab-2').length, 0


  test 'tab panel content should be loaded when tab is activated', ->
    # verify the content is not present before being activated
    equal $('#tab-2').children().length, 0
    # activate
    view.$el.find('.group-category-tab-link:last').click()
    ok $('#tab-2').children().length > 0
