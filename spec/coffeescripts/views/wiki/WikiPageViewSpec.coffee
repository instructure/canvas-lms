define [
  'underscore'
  'compiled/models/WikiPage'
  'compiled/views/wiki/WikiPageView'
], (_, WikiPage, WikiPageView) ->
  
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
    @sandbox.useFakeTimers(new Date(2012, 0, 31).getTime())
    model = new WikiPage
      locked_for_user: true
      lock_info:
        unlock_at: '2012-02-15T12:00:00Z'
    view = new WikiPageView
      model: model
    ok !!view.toJSON().lock_info?.unlock_at.match('Feb'), 'lock_info.unlock_at reformatted and represented in toJSON'

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
      UPDATE_CONTENT: false
      DELETE: false
      READ_REVISIONS: false
      ACCESS_GEAR_MENU: false

  testRights 'CAN (null)',
    CAN:
      VIEW_PAGES: false
      PUBLISH: false
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
      UPDATE_CONTENT: true
      DELETE: false
      READ_REVISIONS: true
      ACCESS_GEAR_MENU: true


  module 'WikiPageView:locked'

  testLockedPage = (subject, options) ->
    test subject, ->
      @sandbox.useFakeTimers(new Date(2012, 0, 31).getTime())

      model = new WikiPage _.extend(locked_for_user: true, options?.attributes)
      view = new WikiPageView _.extend(model: model, options?.view_options)
      view.render()

      locked_alert = view.$el.find('.locked-alert').html()
      if options?.matches
        for match in options.matches
          ok locked_alert.match(match), "matched '#{match}'"
      if options?.negative_matches
        for match in options.negative_matches
          ok !locked_alert.match(match), "did not match '#{match}'"

  testLockedPage 'locked_for_user',
    matches: ['locked']

  testLockedPage 'unlock_at',
    attributes:
      lock_info:
        unlock_at: '2012-02-15T12:00:00Z'
    matches: ['available on']

  testLockedPage 'unlock_at (in the past)',
    attributes:
      lock_info:
        unlock_at: '2012-01-01T12:00:00Z'
    negative_matches: ['available on']

  testLockedPage 'module.prerequisite.name',
    attributes:
      lock_info:
        context_module:
          prerequisites: [
            type: 'context_module'
            name: 'context module'
          ,
            type: 'context_module'
            name: 'other module'
          ]
    matches: ['context module', 'other module']

  testLockedPage 'module.prerequisite.name, unlock_at',
    attributes:
      lock_info:
        context_module:
          prerequisites: [
            type: 'context_module'
            name: 'context module'
          ,
            type: 'context_module'
            name: 'other module'
          ]
        unlock_at: '2012-02-15T12:00:00Z'
    matches: ['context module', 'other module', 'available on']

  testLockedPage 'modules_path, module.prerequisite.id, module.prerequisite.name',
    attributes:
      lock_info:
        context_module:
          prerequisites: [
            id: 'module_id'
            type: 'context_module'
            name: 'context module'
          ,
            id: 'other_id'
            type: 'context_module'
            name: 'other module'
          ]
    view_options:
      modules_path: 'modules_path'
    matches: ['context module', 'other module', 'href', 'modules_path/module_id']

  testLockedPage 'modules_path, module.prerequisite.id, module.prerequisite.name, unlock_at',
    attributes:
      lock_info:
        context_module:
          prerequisites: [
            id: 'module_id'
            type: 'context_module'
            name: 'context module'
          ,
            id: 'other_id'
            type: 'context_module'
            name: 'other module'
          ]
        unlock_at: '2012-01-01T12:00:00Z'
    view_options:
      modules_path: 'modules_path'
    matches: ['context module', 'other module', 'href', 'modules_path/module_id', 'available on']
