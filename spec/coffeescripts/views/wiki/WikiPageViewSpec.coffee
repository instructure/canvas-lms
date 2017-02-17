define [
  'underscore'
  'compiled/models/WikiPage'
  'compiled/views/wiki/WikiPageView'
], (_, WikiPage, WikiPageView) ->

  QUnit.module 'WikiPageView'

  test 'display_show_all_pages makes it through constructor', ->
    model = new WikiPage
    view = new WikiPageView
      model: model
      display_show_all_pages: true
    equal(true, view.display_show_all_pages)

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


  QUnit.module 'WikiPageView:JSON'

  test 'modules_path', ->
    model = new WikiPage
    view = new WikiPageView
      model: model
      modules_path: '/courses/73/modules'
    strictEqual view.toJSON().modules_path, '/courses/73/modules', 'modules_path represented in toJSON'

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

  test 'wiki_page_history_path', ->
    model = new WikiPage
    view = new WikiPageView
      model: model
      wiki_page_edit_path: '/groups/73/pages/37/revisions'
    strictEqual view.toJSON().wiki_page_edit_path, '/groups/73/pages/37/revisions', 'wiki_page_history_path represented in toJSON'

  test 'lock_info.unlock_at', ->
    clock = sinon.useFakeTimers(new Date(2012, 0, 31).getTime())
    model = new WikiPage
      locked_for_user: true
      lock_info:
        unlock_at: '2012-02-15T12:00:00Z'
    view = new WikiPageView
      model: model
    ok !!view.toJSON().lock_info?.unlock_at.match('Feb'), 'lock_info.unlock_at reformatted and represented in toJSON'
    clock.restore()

  testRights = (subject, options) ->
    test "#{subject}", ->
      model = new WikiPage options.attributes, contextAssetString: options.contextAssetString
      view = new WikiPageView
        model: model
        WIKI_RIGHTS: options.WIKI_RIGHTS
        PAGE_RIGHTS: options.PAGE_RIGHTS
        course_home: options.course_home
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
      read_revisions: true
    CAN:
      VIEW_PAGES: true
      PUBLISH: true
      VIEW_UNPUBLISHED: true
      UPDATE_CONTENT: true
      DELETE: true
      READ_REVISIONS: true
      ACCESS_GEAR_MENU: true

  testRights 'CAN (update)',
    contextAssetString: 'group_73'
    WIKI_RIGHTS:
      read: true
      manage: true
    PAGE_RIGHTS:
      update_content: true
      read_revisions: true
    CAN:
      VIEW_PAGES: true
      PUBLISH: false
      VIEW_UNPUBLISHED: true
      UPDATE_CONTENT: true
      DELETE: false
      READ_REVISIONS: true
      ACCESS_GEAR_MENU: true

  testRights 'CAN (read)',
    contextAssetString: 'course_73'
    WIKI_RIGHTS:
      read: true
    PAGE_RIGHTS:
      read: true
    CAN:
      VIEW_PAGES: true
      PUBLISH: false
      VIEW_UNPUBLISHED: false
      UPDATE_CONTENT: false
      DELETE: false
      READ_REVISIONS: false
      ACCESS_GEAR_MENU: false

  testRights 'CAN (null)',
    CAN:
      VIEW_PAGES: false
      PUBLISH: false
      VIEW_UNPUBLISHED: false
      UPDATE_CONTENT: false
      DELETE: false
      READ_REVISIONS: false
      ACCESS_GEAR_MENU: false

  testRights 'CAN (manage, course home page)',
    contextAssetString: 'course_73'
    course_home: true
    WIKI_RIGHTS:
      read: true
      manage: true
    PAGE_RIGHTS:
      update: true
      delete: true
      read_revisions: true
    CAN:
      VIEW_PAGES: true
      PUBLISH: true
      VIEW_UNPUBLISHED: true
      UPDATE_CONTENT: true
      DELETE: false
      READ_REVISIONS: true
      ACCESS_GEAR_MENU: true
