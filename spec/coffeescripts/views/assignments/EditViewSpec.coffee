define [
  'jquery'
  'underscore'
  'compiled/collections/SectionCollection'
  'compiled/models/Assignment'
  'compiled/models/DueDateList'
  'compiled/models/Section'
  'compiled/views/assignments/AssignmentGroupSelector'
  'compiled/views/assignments/DueDateOverride'
  'compiled/views/assignments/EditView'
  'compiled/views/assignments/GradingTypeSelector'
  'compiled/views/assignments/GroupCategorySelector'
  'compiled/views/assignments/PeerReviewsSelector'
  'helpers/fakeENV'
  'compiled/userSettings'
  'helpers/jquery.simulate'
], (
  $,
  _,
  SectionCollection,
  Assignment,
  DueDateList,
  Section,
  AssignmentGroupSelector,
  DueDateOverrideView,
  EditView,
  GradingTypeSelector,
  GroupCategorySelector,
  PeerReviewsSelector,
  fakeENV,
  userSettings) ->

  s_params = 'some super secure params'

  nameLengthHelper = (view, length, maxNameLengthRequiredForAccount, maxNameLength, postToSis) ->
    name = 'a'.repeat(length)
    ENV.MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT = maxNameLengthRequiredForAccount
    ENV.MAX_NAME_LENGTH = maxNameLength
    return view.validateBeforeSave({name: name, post_to_sis: postToSis}, [])

  editView = (assignmentOpts = {}) ->
    defaultAssignmentOpts =
      name: 'Test Assignment'
      secure_params: s_params
      assignment_overrides: []

    assignmentOpts = _.extend {}, assignmentOpts, defaultAssignmentOpts
    assignment = new Assignment assignmentOpts

    sectionList = new SectionCollection [Section.defaultDueDateSection()]
    dueDateList = new DueDateList assignment.get('assignment_overrides'), sectionList, assignment

    assignmentGroupSelector = new AssignmentGroupSelector
      parentModel: assignment
      assignmentGroups: ENV?.ASSIGNMENT_GROUPS || []
    gradingTypeSelector = new GradingTypeSelector
      parentModel: assignment
    groupCategorySelector = new GroupCategorySelector
      parentModel: assignment
      groupCategories: ENV?.GROUP_CATEGORIES || []
      inClosedGradingPeriod: assignment.inClosedGradingPeriod()
    peerReviewsSelector = new PeerReviewsSelector
      parentModel: assignment

    app = new EditView
      model: assignment
      assignmentGroupSelector: assignmentGroupSelector
      gradingTypeSelector: gradingTypeSelector
      groupCategorySelector: groupCategorySelector
      peerReviewsSelector: peerReviewsSelector
      views:
        'js-assignment-overrides': new DueDateOverrideView
          model: dueDateList
          views: {}

    app.render()

  QUnit.module 'EditView',
    setup: ->
      fakeENV.setup({
        current_user_roles: ['teacher'],
        VALID_DATE_RANGE: {},
        COURSE_ID: 1,
      })
      @server = sinon.fakeServer.create()

    teardown: ->
      @server.restore()
      fakeENV.teardown()
      $(".ui-dialog").remove()
      $("ul[id^=ui-id-]").remove()
      $(".form-dialog").remove()
      document.getElementById("fixtures").innerHTML = ""

    editView: ->
      editView.apply(this, arguments)

  test 'renders', ->
    view = @editView()
    equal view.$('#assignment_name').val(), 'Test Assignment'

  test 'rejects missing group set for group assignment', ->
    view = @editView()
    data = { group_category_id: 'blank' }
    errors = view.validateBeforeSave(data, [])
    equal errors['newGroupCategory'][0]['message'], 'Please create a group set'

  test 'rejects a letter for points_possible', ->
    view = @editView()
    data = points_possible: 'a'
    errors = view.validateBeforeSave(data, [])
    equal errors['points_possible'][0]['message'], 'Points possible must be a number'

  test 'does not allow group assignment for large rosters', ->
    ENV.IS_LARGE_ROSTER = true
    view = @editView()
    equal view.$("#group_category_selector").length, 0

  test 'does not allow peer review for large rosters', ->
    ENV.IS_LARGE_ROSTER = true
    view = @editView()
    equal view.$("#assignment_peer_reviews_fields").length, 0

  test 'adds and removes student group', ->
    ENV.GROUP_CATEGORIES = [{id: 1, name: "fun group"}]
    ENV.ASSIGNMENT_GROUPS = [{id: 1, name: "assignment group 1"}]
    view = @editView()
    equal view.assignment.toView()['groupCategoryId'], null

  test 'does not allow point value of -1 or less if grading type is letter', ->
    view = @editView()
    data = points_possible: '-1', grading_type: 'letter_grade'
    errors = view._validatePointsRequired(data, [])
    equal errors['points_possible'][0]['message'], 'Points possible must be 0 or more for selected grading type'

  test "requires name to save assignment", ->
    view = @editView()
    data =
      name: ""
    errors = view.validateBeforeSave(data, [])

    ok errors["name"]
    equal errors["name"].length, 1
    equal errors["name"][0]["message"], "Name is required!"

  test "has an error when a name > 255 chars", ->
    view = @editView()
    errors = nameLengthHelper(view, 257, false, 30, '0')
    ok errors["name"]
    equal errors["name"].length, 1
    equal errors["name"][0]["message"], "Name is too long, must be under 256 characters"

  test "allows assignment to save when a name < 255 chars, MAX_NAME_LENGTH is not required and post_to_sis is true", ->
    view = @editView()
    errors = nameLengthHelper(view, 254, false, 30, '1')
    equal errors.length, 0

  test "allows assignment to save when a name < 255 chars, MAX_NAME_LENGTH is not required and post_to_sis is false", ->
    view = @editView()
    errors = nameLengthHelper(view, 254, false, 30, '0')
    equal errors.length, 0

  test "has an error when a name > MAX_NAME_LENGTH chars if MAX_NAME_LENGTH is custom, required and post_to_sis is true", ->
    view = @editView()
    errors = nameLengthHelper(view, 35, true, 30, '1')
    ok errors["name"]
    equal errors["name"].length, 1
    equal errors["name"][0]["message"], "Name is too long, must be under #{ENV.MAX_NAME_LENGTH + 1} characters"

  test "allows assignment to save when name > MAX_NAME_LENGTH chars if MAX_NAME_LENGTH is custom, required and post_to_sis is false", ->
    view = @editView()
    errors = nameLengthHelper(view, 35, true, 30, '0')
    equal errors.length, 0

  test "allows assignment to save when name < MAX_NAME_LENGTH chars if MAX_NAME_LENGTH is custom, required and post_to_sis is true", ->
    view = @editView()
    errors = nameLengthHelper(view, 25, true, 30, '1')
    equal errors.length, 0

  test "don't validate name if it is frozen", ->
    view = @editView()
    view.model.set('frozen_attributes', ['title'])

    errors = view.validateBeforeSave({}, [])
    notOk errors["name"]

  test "renders a hidden secure_params field", ->
    view = @editView()
    secure_params = view.$('#secure_params')

    equal secure_params.attr('type'), 'hidden'
    equal secure_params.val(), s_params

  test 'does show error message on assignment point change with submissions', ->
    view = @editView has_submitted_submissions: true
    view.$el.appendTo $('#fixtures')
    notOk view.$el.find('#point_change_warning:visible').attr('aria-expanded')
    view.$el.find('#assignment_points_possible').val(1)
    view.$el.find('#assignment_points_possible').trigger("change")
    ok view.$el.find('#point_change_warning:visible').attr('aria-expanded')
    view.$el.find('#assignment_points_possible').val(0)
    view.$el.find('#assignment_points_possible').trigger("change")
    notOk view.$el.find('#point_change_warning:visible').attr('aria-expanded')

  test 'does show error message on assignment point change without submissions', ->
    view = @editView has_submitted_submissions: false
    view.$el.appendTo $('#fixtures')
    notOk view.$el.find('#point_change_warning:visible').attr('aria-expanded')
    view.$el.find('#assignment_points_possible').val(1)
    view.$el.find('#assignment_points_possible').trigger("change")
    notOk view.$el.find('#point_change_warning:visible').attr('aria-expanded')

  test 'does not allow point value of "" if grading type is letter', ->
    view = @editView()
    data = points_possible: '', grading_type: 'letter_grade'
    errors = view._validatePointsRequired(data, [])
    equal errors['points_possible'][0]['message'], 'Points possible must be 0 or more for selected grading type'

    #removes student group
    view.$('#has_group_category').click()
    equal view.getFormData()['groupCategoryId'], null

  test 'does not allow blank external tool url', ->
    view = @editView()
    data = submission_type: 'external_tool'
    errors = view._validateExternalTool(data, [])
    equal errors["external_tool_tag_attributes[url]"][0]['message'], 'External Tool URL cannot be left blank'

  test 'does not validate allowed extensions if file uploads is not a submission type', ->
    view = @editView()
    data = submission_types: ["online_url"], allowed_extensions: []
    errors = view._validateAllowedExtensions(data, [])
    equal errors["allowed_extensions"], null

  test 'removes group_category_id if an external tool is selected', ->
    view = @editView()
    data = {
      submission_type: 'external_tool'
      group_category_id: '1'
    }
    data = view._unsetGroupsIfExternalTool(data)
    equal data.group_category_id, null

  test 'renders escaped angle brackets properly', ->
    desc = "<p>&lt;E&gt;</p>"
    view = @editView description: "<p>&lt;E&gt;</p>"
    equal view.$description.val().match(desc), desc

  test 'allows changing moderation setting if no graded submissions exist', ->
    ENV.HAS_GRADED_SUBMISSIONS = false
    view = @editView has_submitted_submissions: true, moderated_grading: true
    ok view.$("[type=checkbox][name=moderated_grading]").prop("checked")
    notOk view.$("[type=checkbox][name=moderated_grading]").prop("disabled")
    equal view.$('[type=hidden][name=moderated_grading]').attr('value'), '0'

  test 'locks down moderation setting after students submit', ->
    ENV.HAS_GRADED_SUBMISSIONS = true
    view = @editView has_submitted_submissions: true, moderated_grading: true
    ok view.$("[type=checkbox][name=moderated_grading]").prop("checked")
    ok view.$("[type=checkbox][name=moderated_grading]").prop("disabled")
    equal view.$('[type=hidden][name=moderated_grading]').attr('value'), '1'

  test 'routes to discussion details normally', ->
    view = @editView html_url: 'http://foo'
    equal view.locationAfterSave({}), 'http://foo'

  test 'routes to return_to', ->
    view = @editView html_url: 'http://foo'
    equal view.locationAfterSave({ return_to: 'http://bar' }), 'http://bar'

  test 'cancels to env normally', ->
    ENV.CANCEL_TO = 'http://foo'
    view = @editView()
    equal view.locationAfterCancel({}), 'http://foo'

  test 'cancels to return_to', ->
    ENV.CANCEL_TO = 'http://foo'
    view = @editView()
    equal view.locationAfterCancel({ return_to: 'http://bar' }), 'http://bar'

  test 'disables fields when inClosedGradingPeriod', ->
    view = @editView(in_closed_grading_period: true)
    view.$el.appendTo $('#fixtures')

    ok view.$el.find('#assignment_name').attr('readonly')
    ok view.$el.find('#assignment_points_possible').attr('readonly')
    ok view.$el.find('#assignment_group_id').attr('readonly')
    equal view.$el.find('#assignment_group_id').attr('aria-readonly'), 'true'
    ok view.$el.find('#assignment_grading_type').attr('readonly')
    equal view.$el.find('#assignment_grading_type').attr('aria-readonly'), 'true'
    ok view.$el.find('#has_group_category').attr('readonly')
    equal view.$el.find('#has_group_category').attr('aria-readonly'), 'true'

  test 'does not disable post to sis when inClosedGradingPeriod', ->
    ENV.POST_TO_SIS = true
    view = @editView(in_closed_grading_period: true)
    view.$el.appendTo $('#fixtures')
    notOk view.$el.find('#assignment_post_to_sis').attr('disabled')

  test 'disableCheckbox is called for a disabled checkbox', ->
    view = @editView(in_closed_grading_period: true)
    view.$el.appendTo $('#fixtures')
    $('<input type="checkbox" id="checkbox_fixture"/>').appendTo $(view.$el)

    # because we're stubbing so late we must call disableFields() again
    disableCheckboxStub =  @stub view, 'disableCheckbox'
    view.disableFields()

    equal disableCheckboxStub.called, true

  test 'ignoreClickHandler is called for a disabled radio', ->
    view = @editView(in_closed_grading_period: true)
    view.$el.appendTo $('#fixtures')

    $('<input type="radio" id="fixture_radio"/>').appendTo $(view.$el)

    # because we're stubbing so late we must call disableFields() again
    ignoreClickHandlerStub =  @stub view, 'ignoreClickHandler'
    view.disableFields()

    view.$el.find('#fixture_radio').click()
    equal ignoreClickHandlerStub.calledOnce, true

  test 'lockSelectValueHandler is called for a disabled select', ->
    view = @editView(in_closed_grading_period: true)
    view.$el.html('')
    $('<select id="select_fixture"><option selected>1</option></option>2</option></select>').appendTo $(view.$el)
    view.$el.appendTo $('#fixtures')

    # because we're stubbing so late we must call disableFields() again
    lockSelectValueHandlerStub =  @stub view, 'lockSelectValueHandler'
    view.disableFields()
    equal lockSelectValueHandlerStub.calledOnce, true

  test 'lockSelectValueHandler freezes selected value', ->
    view = @editView(in_closed_grading_period: true)
    view.$el.html('')
    $('<select id="select_fixture"><option selected>1</option></option>2</option></select>').appendTo $(view.$el)
    view.$el.appendTo $('#fixtures')

    selectedValue = view.$el.find('#fixture_select').val()
    view.$el.find('#fixture_select').val(2).trigger('change')
    equal view.$el.find('#fixture_select').val(), selectedValue

  test 'fields are enabled when not inClosedGradingPeriod', ->
    view = @editView()
    view.$el.appendTo $('#fixtures')

    notOk view.$el.find('#assignment_name').attr('readonly')
    notOk view.$el.find('#assignment_points_possible').attr('readonly')
    notOk view.$el.find('#assignment_group_id').attr('readonly')
    notOk view.$el.find('#assignment_group_id').attr('aria-readonly')
    notOk view.$el.find('#assignment_grading_type').attr('readonly')
    notOk view.$el.find('#assignment_grading_type').attr('aria-readonly')
    notOk view.$el.find('#has_group_category').attr('readonly')
    notOk view.$el.find('#has_group_category').attr('aria-readonly')

  QUnit.module 'EditView: handleGroupCategoryChange',
    setup: ->
      fakeENV.setup()
      ENV.COURSE_ID = 1
      @server = sinon.fakeServer.create()

    teardown: ->
      @server.restore()
      fakeENV.teardown()
      document.getElementById('fixtures').innerHTML = ''

    editView: ->
      editView.apply(this, arguments)

  test 'calls handleModeratedGradingChange', ->
    view = @editView()
    spy = @spy(view, 'handleModeratedGradingChange')
    view.handleGroupCategoryChange()

    ok spy.calledOnce

  QUnit.module 'EditView: group category inClosedGradingPeriod',
    setup: ->
      fakeENV.setup()
      ENV.COURSE_ID = 1
      @server = sinon.fakeServer.create()

    teardown: ->
      @server.restore()
      fakeENV.teardown()
      document.getElementById("fixtures").innerHTML = ""

    editView: ->
      editView.apply(this, arguments)

  test 'lock down group category after students submit', ->
    view = @editView has_submitted_submissions: true
    ok view.$(".group_category_locked_explanation").length
    ok view.$("#has_group_category").prop("disabled")
    ok view.$("#assignment_group_category_id").prop("disabled")
    notOk view.$("[type=checkbox][name=grade_group_students_individually]").prop("disabled")

    view = @editView has_submitted_submissions: false
    equal view.$(".group_category_locked_explanation").length, 0
    notOk view.$("#has_group_category").prop("disabled")
    notOk view.$("#assignment_group_category_id").prop("disabled")
    notOk view.$("[type=checkbox][name=grade_group_students_individually]").prop("disabled")

  QUnit.module 'EditView: enableCheckbox',
    setup: ->
      fakeENV.setup()
      ENV.COURSE_ID = 1
      @server = sinon.fakeServer.create()

    teardown: ->
      @server.restore()
      fakeENV.teardown()
      document.getElementById('fixtures').innerHTML = ''

    editView: ->
      editView.apply(this, arguments)

  test 'enables checkbox', ->
    view = @editView()
    @stub(view.$('#assignment_peer_reviews'), 'parent').returns(view.$('#assignment_peer_reviews'))

    view.$('#assignment_peer_reviews').prop('disabled', true)
    view.enableCheckbox(view.$('#assignment_peer_reviews'))

    notOk view.$('#assignment_peer_reviews').prop('disabled')

  test 'does nothing if assignment is in closed grading period', ->
    view = @editView()
    @stub(view.assignment, 'inClosedGradingPeriod').returns true

    view.$('#assignment_peer_reviews').prop('disabled', true)
    view.enableCheckbox(view.$('#assignment_peer_reviews'))

    ok view.$('#assignment_peer_reviews').prop('disabled')

  QUnit.module 'EditView: setDefaultsIfNew',
    setup: ->
      fakeENV.setup()
      ENV.COURSE_ID = 1
      @stub(userSettings, 'contextGet').returns {submission_types: "foo", peer_reviews: "1", assignment_group_id: 99}
      @server = sinon.fakeServer.create()

    teardown: ->
      @server.restore()
      fakeENV.teardown()
      document.getElementById("fixtures").innerHTML = ""

    editView: ->
      editView.apply(this, arguments)

  test 'returns values from localstorage', ->
    view = @editView()
    view.setDefaultsIfNew()

    equal view.assignment.get('submission_types'), "foo"

  test 'returns string booleans as integers', ->
    view = @editView()
    view.setDefaultsIfNew()

    equal view.assignment.get('peer_reviews'), 1

  test 'doesnt overwrite existing assignment settings', ->
    view = @editView()
    view.assignment.set('assignment_group_id', 22)
    view.setDefaultsIfNew()

    equal view.assignment.get('assignment_group_id'), 22

  test 'will overwrite empty arrays', ->
    view = @editView()
    view.assignment.set('submission_types', [])
    view.setDefaultsIfNew()

    equal view.assignment.get('submission_types'), "foo"

  QUnit.module 'EditView: setDefaultsIfNew: no localStorage',
    setup: ->
      fakeENV.setup()
      ENV.COURSE_ID = 1
      @stub(userSettings, 'contextGet').returns null
      @server = sinon.fakeServer.create()

    teardown: ->
      @server.restore()
      fakeENV.teardown()
      document.getElementById("fixtures").innerHTML = ""

    editView: ->
      editView.apply(this, arguments)

  test 'submission_type is online if no cache', ->
    view = @editView()
    view.setDefaultsIfNew()

    equal view.assignment.get('submission_type'), "online"

  QUnit.module 'EditView: cacheAssignmentSettings',
    setup: ->
      fakeENV.setup()
      ENV.COURSE_ID = 1
      @server = sinon.fakeServer.create()

    teardown: ->
      @server.restore()
      fakeENV.teardown()
      document.getElementById("fixtures").innerHTML = ""

    editView: ->
      editView.apply(this, arguments)

  test 'saves valid attributes to localstorage', ->
    view = @editView()
    @stub(view, 'getFormData').returns {points_possible: 34}
    userSettings.contextSet("new_assignment_settings", {})
    view.cacheAssignmentSettings()

    equal 34, userSettings.contextGet("new_assignment_settings")["points_possible"]

  test 'rejects invalid attributes when caching', ->
    view = @editView()
    @stub(view, 'getFormData').returns {invalid_attribute_example: 30}
    userSettings.contextSet("new_assignment_settings", {})
    view.cacheAssignmentSettings()

    equal null, userSettings.contextGet("new_assignment_settings")["invalid_attribute_example"]

  QUnit.module 'EditView: Conditional Release',
    setup: ->
      fakeENV.setup()
      ENV.COURSE_ID = 1
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
      ENV.CONDITIONAL_RELEASE_ENV = { assignment: { id: 1 }, jwt: 'foo' }
      $(document).on 'submit', -> false
      @server = sinon.fakeServer.create()

    teardown: ->
      @server.restore()
      fakeENV.teardown()
      $(document).off 'submit'
      document.getElementById("fixtures").innerHTML = ""

    editView: ->
      editView.apply(this, arguments)

  test 'attaches conditional release editor', ->
    view = @editView()
    equal 1, view.$conditionalReleaseTarget.children().size()

  test 'calls update on first switch', ->
    view = @editView()
    stub = @stub(view.conditionalReleaseEditor, 'updateAssignment')
    view.updateConditionalRelease()
    ok stub.calledOnce

  test 'calls update when modified once', ->
    view = @editView()
    stub = @stub(view.conditionalReleaseEditor, 'updateAssignment')
    view.onChange()
    view.updateConditionalRelease()
    ok stub.calledOnce

  test 'does not call update when not modified', ->
    view = @editView()
    stub = @stub(view.conditionalReleaseEditor, 'updateAssignment')
    view.updateConditionalRelease()
    stub.reset()
    view.updateConditionalRelease()
    notOk stub.called

  test 'validates conditional release', ->
    view = @editView()
    ENV.ASSIGNMENT = view.assignment
    stub = @stub(view.conditionalReleaseEditor, 'validateBeforeSave').returns 'foo'
    errors = view.validateBeforeSave(view.getFormData(), {})
    ok errors['conditional_release'] == 'foo'

  test 'calls save in conditional release', (assert) ->
    resolved = assert.async()

    view = @editView()
    superPromise = $.Deferred().resolve().promise()
    crPromise = $.Deferred().resolve().promise()
    mockSuper = sinon.mock(EditView.__super__)
    mockSuper.expects('saveFormData').returns superPromise
    stub = @stub(view.conditionalReleaseEditor, 'save').returns crPromise

    finalPromise = view.saveFormData()
    finalPromise.then ->
      mockSuper.verify()
      ok stub.calledOnce
      resolved()

  test 'focuses in conditional release editor if conditional save validation fails', ->
    view = @editView()
    focusOnError = @stub(view.conditionalReleaseEditor, 'focusOnError')
    view.showErrors({ conditional_release: {type:'foo'} })
    ok focusOnError.called

  QUnit.module 'Editview: Intra-Group Peer Review toggle',
    setup: ->
      fakeENV.setup()
      ENV.COURSE_ID = 1
      @server = sinon.fakeServer.create()

    teardown: ->
      @server.restore()
      fakeENV.teardown()
      document.getElementById("fixtures").innerHTML = ""

    editView: ->
      editView.apply(this, arguments)

  test 'only appears for group assignments', ->
    @stub(userSettings, 'contextGet').returns {
      peer_reviews: "1",
      group_category_id: 1,
      automatic_peer_reviews: "1"
    }
    view = @editView()
    view.$el.appendTo $('#fixtures')
    ok view.$('#intra_group_peer_reviews').is(":visible")

  test 'does not appear when reviews are being assigned manually', ->
    @stub(userSettings, 'contextGet').returns {peer_reviews: "1", group_category_id: 1}
    view = @editView()
    view.$el.appendTo $('#fixtures')
    notOk view.$('#intra_group_peer_reviews').is(":visible")

  test 'toggle does not appear when there is no group', ->
    @stub(userSettings, 'contextGet').returns {peer_reviews: "1"}
    view = @editView()
    view.$el.appendTo $('#fixtures')
    notOk view.$('#intra_group_peer_reviews').is(":visible")

  QUnit.module 'EditView: Assignment Configuration Tools',
    setup: ->
      fakeENV.setup()
      ENV.COURSE_ID = 1
      ENV.PLAGIARISM_DETECTION_PLATFORM = true
      @server = sinon.fakeServer.create()

    teardown: ->
      @server.restore()
      fakeENV.teardown()
      document.getElementById("fixtures").innerHTML = ""

    editView: ->
      editView.apply(this, arguments)

  test 'it attaches assignment configuration component', ->
    view = @editView()
    equal view.$similarityDetectionTools.children().size(), 1

  test 'it is hidden if submission type is not online with a file upload', ->
    view = @editView()
    view.$el.appendTo $('#fixtures')
    equal view.$('#similarity_detection_tools').css('display'), 'none'

    view.$('#assignment_submission_type').val('on_paper')
    view.handleSubmissionTypeChange()
    equal view.$('#similarity_detection_tools').css('display'), 'none'

    view.$('#assignment_submission_type').val('external_tool')
    view.handleSubmissionTypeChange()
    equal view.$('#similarity_detection_tools').css('display'), 'none'

    view.$('#assignment_submission_type').val('online')
    view.$('#assignment_online_upload').attr('checked', false)
    view.handleSubmissionTypeChange()
    equal view.$('#similarity_detection_tools').css('display'), 'none'

    view.$('#assignment_submission_type').val('online')
    view.$('#assignment_online_upload').attr('checked', true)
    view.handleSubmissionTypeChange()
    equal view.$('#similarity_detection_tools').css('display'), 'block'

  test 'it is hidden if the plagiarism_detection_platform flag is disabled', ->
    ENV.PLAGIARISM_DETECTION_PLATFORM = false
    view = @editView()
    view.$('#assignment_submission_type').val('online')
    view.$('#assignment_online_upload').attr('checked', true)
    view.handleSubmissionTypeChange()
    equal view.$('#similarity_detection_tools').css('display'), 'none'
