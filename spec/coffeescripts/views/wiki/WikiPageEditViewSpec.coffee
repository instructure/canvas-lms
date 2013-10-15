define [
  'jquery'
  'compiled/models/WikiPage'
  'compiled/views/wiki/WikiPageEditView'
  'wikiSidebar'
], ($, WikiPage, WikiPageEditView, wikiSidebar) ->

  module 'WikiPageEditView:Init',
    setup: ->
      @initStub = sinon.stub(wikiSidebar, 'init')
      @scrollSidebarStub = sinon.stub($, 'scrollSidebar')
      @attachWikiEditorStub = sinon.stub(wikiSidebar, 'attachToEditor')
      @attachWikiEditorStub.returns(show: sinon.stub())
    teardown: ->
      @scrollSidebarStub.restore()
      @initStub.restore()
      @attachWikiEditorStub.restore()

  test 'init wiki sidebar during render', ->
    wikiPageEditView = new WikiPageEditView
    wikiPageEditView.render()
    ok @initStub.calledOnce, 'Called wikiSidebar init once'

  test 'scroll sidebar during render', ->
    wikiPageEditView = new WikiPageEditView
    wikiPageEditView.render()
    ok @scrollSidebarStub.calledOnce, 'Called scrollSidebar once'

  test 'wiki body gets attached to the wikisidebar', ->
    wikiPageEditView = new WikiPageEditView
    wikiPageEditView.render()
    ok @attachWikiEditorStub.calledOnce, 'Attached wikisidebar to body'

  module 'WikiPageEditView:UnsavedChanges',
    setup: ->
      @initStub = sinon.stub(wikiSidebar, 'init')
      @scrollSidebarStub = sinon.stub($, 'scrollSidebar')
      @attachWikiEditorStub = sinon.stub(wikiSidebar, 'attachToEditor')
      @attachWikiEditorStub.returns(show: sinon.stub())

      @wikiPage = new WikiPage
      @view = new WikiPageEditView
        model: @wikiPage
      @view.$el.appendTo $('#fixtures')
      @view.render()

      @titleInput = @view.$el.find('[name="title"]')
      @bodyInput = @view.$el.find('[name="body"]')
    teardown: ->
      @scrollSidebarStub.restore()
      @initStub.restore()
      @attachWikiEditorStub.restore()
      @view.remove()
      $(window).off('beforeunload')

  test 'check for unsaved changes on new model', ->
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
    @wikiPage.set('title', 'nooo')
    @wikiPage.set('body', 'blargh')

    @titleInput.val('nooo')
    @bodyInput.val('blargh')
    ok !@view.hasUnsavedChanges(), 'No changes'
    @titleInput.val('')
    ok @view.hasUnsavedChanges(), 'Changed title'
    @titleInput.val('nooo')
    ok !@view.hasUnsavedChanges(), 'Unchanged title'
    @bodyInput.val('')
    ok @view.hasUnsavedChanges(), 'Changed body'

  test 'warn on cancel if unsaved changes', ->
    @titleInput.val('mwhaha')

    confirmStub = sinon.stub window, 'confirm'
    confirmStub.returns false

    sinonSpy = sinon.spy(@view, 'trigger')

    @view.$el.find('.cancel').click()
    ok confirmStub.calledOnce, 'Warn on cancel'
    ok !sinonSpy.calledWith('cancel'), "Don't trigger cancel if declined"

    confirmStub.restore()
    confirmStub = sinon.stub window, 'confirm'
    confirmStub.returns true

    @view.$el.find('.cancel').click()
    ok confirmStub.calledOnce, 'Warn on cancel again'
    ok sinonSpy.calledWith('cancel'), "Do trigger cancel if accepted"

    confirmStub.restore()

  test 'warn on leaving if unsaved changes', ->
    strictEqual $(window).triggerHandler('beforeunload'), undefined, "No warning if not changed"

    @titleInput.val('mwhaha')

    ok $(window).triggerHandler('beforeunload') != undefined, "Returns warning if changed"

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
