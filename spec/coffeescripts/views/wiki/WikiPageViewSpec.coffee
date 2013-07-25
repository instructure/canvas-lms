define [
  'compiled/models/WikiPage'
  'compiled/views/wiki/WikiPageView'
], (WikiPage, WikiPageView) ->
  
  module 'WikiPageView'

  test 'model.view maintained by item view', ->
    model = new WikiPage
    view = new WikiPageView
      model: model

    strictEqual model.view, view, 'model.view is set to the item view'
    view.render()
    strictEqual model.view, view, 'model.view is set to the item view'

  test 'detach/reattach the publish icon view', ->
    model = new WikiPage
    view = new WikiPageView
      model: model
    view.render()

    $previousEl = view.$el.find('> *:first-child')
    view.publishButtonView.$el.data('test-data', 'test-is-good')

    view.render()

    equal $previousEl.parent().length, 0, 'previous content removed'
    equal view.publishButtonView.$el.data('test-data'), 'test-is-good', 'test data preserved (by detach)'


  module 'WikiPageView:JSON'

  test 'wiki_pages_path', ->
    model = new WikiPage
    view = new WikiPageView
      model: model
      wiki_pages_path: '/groups/73/pages'
    strictEqual view.toJSON().wiki_pages_path, '/groups/73/pages', 'wiki_pages_path represented in toJSON'

  test 'wiki_page_edit_path', ->
    model = new WikiPage
    view = new WikiPageView
      model: model
      wiki_page_edit_path: '/groups/73/pages/37'
    strictEqual view.toJSON().wiki_page_edit_path, '/groups/73/pages/37', 'wiki_page_edit_path represented in toJSON'

  test 'WIKI_RIGHTS', ->
    model = new WikiPage
    view = new WikiPageView
      model: model
      WIKI_RIGHTS:
        good: true
    strictEqual view.toJSON().WIKI_RIGHTS.good, true, 'WIKI_RIGHTS represented in toJSON'

  test 'PAGE_RIGHTS', ->
    model = new WikiPage
    view = new WikiPageView
      model: model
      PAGE_RIGHTS:
        good: true
    strictEqual view.toJSON().PAGE_RIGHTS.good, true, 'PAGE_RIGHTS represented in toJSON'
