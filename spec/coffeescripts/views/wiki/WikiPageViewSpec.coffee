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

  testRights = (subject, options) ->
    test "#{subject}", ->
      model = new WikiPage options.attributes, contextAssetString: options.contextAssetString
      view = new WikiPageView
        model: model
        WIKI_RIGHTS: options.WIKI_RIGHTS
        PAGE_RIGHTS: options.PAGE_RIGHTS
      json = view.toJSON()
      for key of options.CAN
        strictEqual json.CAN[key], options.CAN[key], "#{subject} - CAN.#{key}"

  testRights 'CAN (manage)',
    contextAssetString: 'course_73'
    WIKI_RIGHTS:
      read: true
      manage: true
    PAGE_RIGHTS:
      update: true
      delete: true
    CAN:
      VIEW_PAGES: true
      PUBLISH: true
      UPDATE_CONTENT: true
      DELETE: true

  testRights 'CAN (update)',
    contextAssetString: 'group_73'
    WIKI_RIGHTS:
      read: true
      manage: true
    PAGE_RIGHTS:
      update_content: true
    CAN:
      VIEW_PAGES: true
      PUBLISH: false
      UPDATE_CONTENT: true
      DELETE: false

  testRights 'CAN (read)',
    contextAssetString: 'course_73'
    WIKI_RIGHTS:
      read: true
    PAGE_RIGHTS:
      read: true
    CAN:
      VIEW_PAGES: true
      PUBLISH: false
      UPDATE_CONTENT: false
      DELETE: false

  testRights 'CAN (null)',
    CAN:
      VIEW_PAGES: false
      PUBLISH: false
      UPDATE_CONTENT: false
      DELETE: false
