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
], ($, _, SectionCollection, Assignment, DueDateList, Section,
  AssignmentGroupSelector, DueDateOverrideView, EditView,
  GradingTypeSelector, GroupCategorySelector, PeerReviewsSelector, fakeENV, userSettings) ->

  s_params = 'asdf32.asdf31.asdf2'

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

    app.enableCheckbox = () -> {}
    app.render()

  module 'EditView',
    setup: ->
      fakeENV.setup()
      ENV.VALID_DATE_RANGE = {}
      ENV.COURSE_ID = 1
    teardown: ->
      fakeENV.teardown()
      $(".ui-dialog").remove()
      $("ul[id^=ui-id-]").remove()
      $(".form-dialog").remove()
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

  test "requires a name < 255 chars to save assignment", ->
    view = @editView()
    l1 = 'aaaaaaaaaa'
    l2 = l1 + l1 + l1 + l1 + l1 + l1
    l3 = l2 + l2 + l2 + l2 + l2 + l2
    ok l3.length > 255

    errors = view.validateBeforeSave(name: l3, [])
    ok errors["name"]
    equal errors["name"].length, 1
    equal errors["name"][0]["message"], "Name is too long"

  test "don't validate name if it is frozen", ->
    view = @editView()
    view.model.set('frozen_attributes', ['title'])

    errors = view.validateBeforeSave({}, [])
    ok !errors["name"]

  test "renders a hidden secure_params field", ->
    view = @editView()
    secure_params = view.$('#secure_params')

    equal secure_params.attr('type'), 'hidden'
    equal secure_params.val(), s_params

  test 'does show error message on assignment point change with submissions', ->
    view = @editView has_submitted_submissions: true
    view.$el.appendTo $('#fixtures')
    ok !view.$el.find('#point_change_warning:visible').attr('aria-expanded')
    view.$el.find('#assignment_points_possible').val(1)
    view.$el.find('#assignment_points_possible').trigger("change")
    ok view.$el.find('#point_change_warning:visible').attr('aria-expanded')
    view.$el.find('#assignment_points_possible').val(0)
    view.$el.find('#assignment_points_possible').trigger("change")
    ok !view.$el.find('#point_change_warning:visible').attr('aria-expanded')

  test 'does show error message on assignment point change without submissions', ->
    view = @editView has_submitted_submissions: false
    view.$el.appendTo $('#fixtures')
    ok !view.$el.find('#point_change_warning:visible').attr('aria-expanded')
    view.$el.find('#assignment_points_possible').val(1)
    view.$el.find('#assignment_points_possible').trigger("change")
    ok !view.$el.find('#point_change_warning:visible').attr('aria-expanded')

  test 'does not allow point value of "" if grading type is letter', ->
    view = @editView()
    data = points_possible: '', grading_type: 'letter_grade'
    errors = view._validatePointsRequired(data, [])
    equal errors['points_possible'][0]['message'], 'Points possible must be 0 or more for selected grading type'

    #fragile spec on Firefox, Safari
    #adds student group
    # view.$('#has_group_category').click()
    # view.$('#assignment_group_category_id option:eq(0)').attr("selected", "selected")
    # equal view.getFormData()['group_category_id'], "1"

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
    ok !view.$("[type=checkbox][name=moderated_grading]").prop("disabled")
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


  module 'EditView: group category locked',
    setup: ->
      fakeENV.setup()
      ENV.COURSE_ID = 1
      @oldAddGroupCategory = window.addGroupCategory
      window.addGroupCategory = @stub()
    teardown: ->
      fakeENV.teardown()
      window.addGroupCategory = @oldAddGroupCategory
    editView: ->
      editView.apply(this, arguments)

  test 'lock down group category after students submit', ->
    view = @editView has_submitted_submissions: true
    ok view.$(".group_category_locked_explanation").length
    ok view.$("#has_group_category").prop("disabled")
    ok view.$("#assignment_group_category_id").prop("disabled")
    ok !view.$("[type=checkbox][name=grade_group_students_individually]").prop("disabled")

    view = @editView has_submitted_submissions: false
    equal view.$(".group_category_locked_explanation").length, 0
    ok !view.$("#has_group_category").prop("disabled")
    ok !view.$("#assignment_group_category_id").prop("disabled")
    ok !view.$("[type=checkbox][name=grade_group_students_individually]").prop("disabled")

  module 'EditView: setDefaultsIfNew',
    setup: ->
      fakeENV.setup()
      ENV.COURSE_ID = 1
      @stub(userSettings, 'contextGet').returns {submission_types: "foo", peer_reviews: "1", assignment_group_id: 99}
    teardown: ->
      fakeENV.teardown()
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

  module 'EditView: setDefaultsIfNew: no localStorage',
    setup: ->
      fakeENV.setup()
      ENV.COURSE_ID = 1
      @stub(userSettings, 'contextGet').returns null
    teardown: ->
      fakeENV.teardown()
    editView: ->
      editView.apply(this, arguments)

  test 'submission_type is online if no cache', ->
    view = @editView()
    view.setDefaultsIfNew()

    equal view.assignment.get('submission_type'), "online"

  module 'EditView: cacheAssignmentSettings',
    setup: ->
      fakeENV.setup()
      ENV.COURSE_ID = 1
    teardown: ->
      fakeENV.teardown()
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

  module 'EditView: Conditional Release',
    setup: ->
      fakeENV.setup()
      ENV.COURSE_ID = 1
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
      ENV.CONDITIONAL_RELEASE_ENV = { assignment: { id: 1 }, jwt: 'foo' }
      $(document).on 'submit', -> false
    teardown: ->
      fakeENV.teardown()
      $(document).off 'submit'
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
    view.showErrors({ conditional_release: 'foo' })
    ok focusOnError.called

  module 'Editview: Intra-Group Peer Review toggle',
    setup: ->
      fakeENV.setup()
      ENV.COURSE_ID = 1
    teardown: ->
      fakeENV.teardown()
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
    ok !view.$('#intra_group_peer_reviews').is(":visible")

  test 'toggle does not appear when there is no group', ->
    @stub(userSettings, 'contextGet').returns {peer_reviews: "1"}
    view = @editView()
    view.$el.appendTo $('#fixtures')
    ok !view.$('#intra_group_peer_reviews').is(":visible")

  module 'EditView: Assignment Configuration Tools',
    setup: ->
      fakeENV.setup()
      ENV.COURSE_ID = 1
      ENV.PLAGIARISM_DETECTION_PLATFORM = true

    teardown: ->
      fakeENV.teardown()

    editView: ->
      editView.apply(this, arguments)

  test 'it attaches assignment configuration component', ->
    view = @editView()
    equal view.$assignmentConfigurationTools.children().size(), 1

  test 'it is hidden if submission type is not online with a file upload', ->
    view = @editView()
    view.$el.appendTo $('#fixtures')
    equal view.$('#assignment_configuration_tools').css('display'), 'none'

    view.$('#assignment_submission_type').val('on_paper')
    view.handleSubmissionTypeChange()
    equal view.$('#assignment_configuration_tools').css('display'), 'none'

    view.$('#assignment_submission_type').val('external_tool')
    view.handleSubmissionTypeChange()
    equal view.$('#assignment_configuration_tools').css('display'), 'none'

    view.$('#assignment_submission_type').val('online')
    view.$('#assignment_online_upload').attr('checked', false)
    view.handleSubmissionTypeChange()
    equal view.$('#assignment_configuration_tools').css('display'), 'none'

    view.$('#assignment_submission_type').val('online')
    view.$('#assignment_online_upload').attr('checked', true)
    view.handleSubmissionTypeChange()
    equal view.$('#assignment_configuration_tools').css('display'), 'block'

  test 'it is hidden if the plagiarism_detection_platform flag is disabled', ->
    ENV.PLAGIARISM_DETECTION_PLATFORM = false
    view = @editView()
    view.$('#assignment_submission_type').val('online')
    view.$('#assignment_online_upload').attr('checked', true)
    view.handleSubmissionTypeChange()
    equal view.$('#assignment_configuration_tools').css('display'), 'none'
