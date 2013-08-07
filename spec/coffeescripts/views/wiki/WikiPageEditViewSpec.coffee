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


  module 'WikiPageEditView:Validate'

  test 'validation of the title is only performed if the title is present', ->
    view = new WikiPageEditView

    errors = view.validateFormData wiki_page: {body: 'blah'}
    strictEqual errors['wiki_page[title]'], undefined, 'no error when title is omitted'

    errors = view.validateFormData wiki_page: {title: 'blah', body: 'blah'}
    strictEqual errors['wiki_page[title]'], undefined, 'no error when title is present'

    errors = view.validateFormData wiki_page: {title: '', body: 'blah'}
    ok errors['wiki_page[title]'], 'error when title is present, but blank'
    ok errors['wiki_page[title]'][0].message, 'error message when title is present, but blank'


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
      EDIT_HIDE: true
      EDIT_ROLES: true
    SHOW:
      OPTIONS: true
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
      EDIT_HIDE: false
      EDIT_ROLES: true
    SHOW:
      OPTIONS: true
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
      EDIT_HIDE: false
      EDIT_ROLES: false
    SHOW:
      OPTIONS: false
      #COURSE_ROLES: false # intentionally omitted as EDIT_ROLES === false

  testRights 'CAN/SHOW (null)',
    attributes:
      url: 'test'
    CAN:
      PUBLISH: false
      DELETE: false
      EDIT_TITLE: false
      EDIT_HIDE: false
      EDIT_ROLES: false
    SHOW:
      OPTIONS: false
      #COURSE_ROLES: false # intentionally omitted as EDIT_ROLES === false
