define [
  'jquery'
  'compiled/models/Assignment'
  'compiled/models/WikiPage'
  'compiled/views/wiki/WikiPageEditView'
  'jsx/shared/rce/RichContentEditor',
  'helpers/fixtures'
  'helpers/editorUtils'
  'helpers/fakeENV'
], ($, Assignment, WikiPage, WikiPageEditView, RichContentEditor, fixtures, editorUtils, fakeENV) ->


  module 'WikiPageEditView:Init',
    setup: ->
      @initSpy = sinon.spy(RichContentEditor, 'initSidebar')

    teardown: ->
      RichContentEditor.initSidebar.restore()
      editorUtils.resetRCE()
      $(window).off('beforeunload')

  test 'init wiki sidebar during render', ->
    wikiPageEditView = new WikiPageEditView
    wikiPageEditView.render()
    ok @initSpy.calledOnce, 'Called richContentEditor.initSidebar once'

  test 'renders escaped angle brackets properly', ->
    body = "<p>&lt;E&gt;</p>"
    wikiPage = new WikiPage body: body
    view = new WikiPageEditView model: wikiPage
    view.render()
    equal view.$wikiPageBody.val(), body

  test 'conditional content is hidden when disabled', ->
    view = new WikiPageEditView
      WIKI_RIGHTS:
        manage: true
    view.render()

    conditionalToggle = view.$el.find('#conditional_content')
    equal conditionalToggle.length, 0, 'Toggle is hidden'

  module 'WikiPageEditView:ConditionalContent',
    setup: ->
      fakeENV.setup(CONDITIONAL_RELEASE_SERVICE_ENABLED: true)

    teardown: ->
      fakeENV.teardown()

  test 'conditional content option hidden for insufficient rights', ->
    view = new WikiPageEditView
      WIKI_RIGHTS:
        read: true
      PAGE_RIGHTS:
        read: true
        update_content: true
    view.render()

    conditionalToggle = view.$el.find('#conditional_content')
    equal conditionalToggle.length, 0, 'Toggle is hidden'

  test 'conditional content option appears', ->
    view = new WikiPageEditView
      WIKI_RIGHTS:
        manage: true
    view.render()

    conditionalToggle = view.$el.find('#conditional_content')
    equal conditionalToggle.length, 1, 'Toggle is visible'
    equal conditionalToggle.prop('checked'), false, 'Toggle is unchecked'

  test 'conditional content option appears populated', ->
    wikiPage = new WikiPage
      set_assignment: true
      assignment: new Assignment
        set_assignment: true
    view = new WikiPageEditView
      model: wikiPage
      WIKI_RIGHTS:
        manage: true
    view.render()

    conditionalToggle = view.$el.find('#conditional_content')
    equal conditionalToggle.prop('checked'), true, 'Toggle is checked'

  test 'conditional content option does stuff', ->
    wikiPage = new WikiPage
    view = new WikiPageEditView
      model: wikiPage
      WIKI_RIGHTS:
        manage: true
    view.render()

    conditionalToggle = view.$el.find('#conditional_content')
    equal conditionalToggle.prop('checked'), false, 'Toggle is unchecked'
    conditionalToggle.prop('checked', true)
    assignment = view.getFormData().assignment
    equal assignment.get('set_assignment'), '1', 'Sets assignment'
    equal assignment.get('only_visible_to_overrides'), '1', 'Sets override visibility'

  module 'WikiPageEditView:UnsavedChanges',
    setup: ->
      fixtures.setup()

    teardown: ->
      fixtures.teardown()
      editorUtils.resetRCE()
      $(window).off('beforeunload')

  setupUnsavedChangesTest = (test, attributes) ->
    setup = ->
      @wikiPage = new WikiPage attributes
      @view = new WikiPageEditView model: @wikiPage
      @view.$el.appendTo('#fixtures')
      @view.render()

      @titleInput = @view.$el.find('[name=title]')
      @bodyInput = @view.$el.find('[name=body]')

      # stub the 'is_dirty' RCE command. NOTE: this stubs only the editorBox
      # version with the feature flag off. force these specs to start failing
      # when run with the feature flag on, at which point this will need to be
      # updated to stub remoteEditor instead
      ok !@bodyInput.data('remoteEditor')
      ok @bodyInput.data('rich_text')
      model = @wikiPage
      bodyInput = @bodyInput
      editorBox = bodyInput.editorBox
      @stub $.fn, 'editorBox', (options) ->
        if options == 'is_dirty'
          return bodyInput.val() != model.get('body')
        else
          editorBox.apply(this, arguments)

    setup.call(test, attributes)

  test 'check for unsaved changes on new model', ->
    setupUnsavedChangesTest(this, title: '', body: '')

    @titleInput.val('blah')
    ok @view.getFormData().title == 'blah', "blah"
    ok @view.hasUnsavedChanges(), 'Changed title'
    @titleInput.val('')
    ok !@view.hasUnsavedChanges(), 'Unchanged title'
    @bodyInput.val('bloo')
    ok @view.hasUnsavedChanges(), 'Changed body'
    @bodyInput.val('')
    ok !@view.hasUnsavedChanges(), 'Unchanged body'

  test 'check for unsaved changes on model with data', ->
    setupUnsavedChangesTest(this, title: 'nooo', body: 'blargh')

    ok !@view.hasUnsavedChanges(), 'No changes'
    @titleInput.val('')
    ok @view.hasUnsavedChanges(), 'Changed title'
    @titleInput.val('nooo')
    ok !@view.hasUnsavedChanges(), 'Unchanged title'
    @bodyInput.val('')
    ok @view.hasUnsavedChanges(), 'Changed body'

  test 'warn on cancel if unsaved changes', ->
    setupUnsavedChangesTest(this, title: 'nooo', body: 'blargh')
    @spy(@view, 'trigger')
    @stub(window, 'confirm')
    @titleInput.val('mwhaha')

    window.confirm.returns(false)
    @view.$el.find('.cancel').click()
    ok window.confirm.calledOnce, 'Warn on cancel'
    ok !@view.trigger.calledWith('cancel'), "Don't trigger cancel if declined"

    window.confirm.reset()
    @view.trigger.reset()

    window.confirm.returns(true)
    @view.$el.find('.cancel').click()
    ok window.confirm.calledOnce, 'Warn on cancel again'
    ok @view.trigger.calledWith('cancel'), 'Do trigger cancel if accepted'

  test 'warn on leaving if unsaved changes', ->
    setupUnsavedChangesTest(this, title: 'nooo', body: 'blargh')

    strictEqual @view.onUnload({}), undefined, "No warning if not changed"

    @titleInput.val('mwhaha')

    ok @view.onUnload({}) isnt undefined, "Returns warning if changed"


  module 'WikiPageEditView:Validate'

  test 'validation of the title is only performed if the title is present', ->
    view = new WikiPageEditView

    errors = view.validateFormData body: 'blah'
    strictEqual errors['title'], undefined, 'no error when title is omitted'

    errors = view.validateFormData title: 'blah', body: 'blah'
    strictEqual errors['title'], undefined, 'no error when title is present'

    errors = view.validateFormData title: '', body: 'blah'
    ok errors['title'], 'error when title is present, but blank'
    ok errors['title'][0].message, 'error message when title is present, but blank'

  module 'WikiPageEditView:JSON'

  testRights = (subject, options) ->
    test "#{subject}", ->
      model = new WikiPage options.attributes, contextAssetString: options.contextAssetString
      view = new WikiPageEditView
        model: model
        WIKI_RIGHTS: options.WIKI_RIGHTS
        PAGE_RIGHTS: options.PAGE_RIGHTS
      json = view.toJSON()
      if options.IS
        for key of options.IS
          strictEqual json.IS[key], options.IS[key], "IS.#{key}"
      if options.CAN
        for key of options.CAN
          strictEqual json.CAN[key], options.CAN[key], "CAN.#{key}"
      if options.SHOW
        for key of options.SHOW
          strictEqual json.SHOW[key], options.SHOW[key], "SHOW.#{key}"

  testRights 'IS (teacher)',
    attributes:
      editing_roles: 'teachers'
    IS:
      TEACHER_ROLE: true
      STUDENT_ROLE: false
      MEMBER_ROLE: false
      ANYONE_ROLE: false

  testRights 'IS (student)',
    attributes:
      editing_roles: 'teachers,students'
    IS:
      TEACHER_ROLE: false
      STUDENT_ROLE: true
      MEMBER_ROLE: false
      ANYONE_ROLE: false

  testRights 'IS (members)',
    attributes:
      editing_roles: 'members'
    IS:
      TEACHER_ROLE: false
      STUDENT_ROLE: false
      MEMBER_ROLE: true
      ANYONE_ROLE: false

  testRights 'IS (course anyone)',
    attributes:
      editing_roles: 'teachers,students,public'
    IS:
      TEACHER_ROLE: false
      STUDENT_ROLE: false
      MEMBER_ROLE: false
      ANYONE_ROLE: true

  testRights 'IS (group anyone)',
    attributes:
      editing_roles: 'members,public'
    IS:
      TEACHER_ROLE: false
      STUDENT_ROLE: false
      MEMBER_ROLE: false
      ANYONE_ROLE: true

  testRights 'IS (null)',
    IS:
      TEACHER_ROLE: true
      STUDENT_ROLE: false
      MEMBER_ROLE: false
      ANYONE_ROLE: false

  testRights 'CAN/SHOW (manage course)',
    contextAssetString: 'course_73'
    attributes:
      url: 'test'
    WIKI_RIGHTS:
      manage: true
      publish_page: true
    PAGE_RIGHTS:
      read: true
      update: true
      delete: true
    CAN:
      PUBLISH: true
      DELETE: true
      EDIT_TITLE: true
      EDIT_ROLES: true
    SHOW:
      COURSE_ROLES: true

  testRights 'CAN/SHOW (manage group)',
    contextAssetString: 'group_73'
    WIKI_RIGHTS:
      manage: true
    PAGE_RIGHTS:
      read: true
    CAN:
      PUBLISH: false
      DELETE: false
      EDIT_TITLE: true # new record
      EDIT_ROLES: true
    SHOW:
      COURSE_ROLES: false

  testRights 'CAN/SHOW (update_content)',
    contextAssetString: 'course_73'
    attributes:
      url: 'test'
    WIKI_RIGHTS:
      read: true
    PAGE_RIGHTS:
      read: true
      update_content: true
    CAN:
      PUBLISH: false
      DELETE: false
      EDIT_TITLE: false
      EDIT_ROLES: false
    #SHOW:
      #COURSE_ROLES: false # intentionally omitted as EDIT_ROLES === false

  testRights 'CAN/SHOW (null)',
    attributes:
      url: 'test'
    CAN:
      PUBLISH: false
      DELETE: false
      EDIT_TITLE: false
      EDIT_ROLES: false
    #SHOW:
      #COURSE_ROLES: false # intentionally omitted as EDIT_ROLES === false
