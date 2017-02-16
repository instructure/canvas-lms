define [
  'compiled/models/Assignment'
  'compiled/models/Submission'
  'compiled/models/DateGroup'
  'helpers/fakeENV'
], (Assignment, Submission, DateGroup, fakeENV) ->

  QUnit.module "Assignment#initialize with ENV.POST_TO_SIS set to false",
    setup: ->
      fakeENV.setup
        POST_TO_SIS: false
    teardown: -> fakeENV.teardown()

  test "must not alter the post_to_sis field", ->
    assignment = new Assignment
    strictEqual assignment.get('post_to_sis'), undefined

  QUnit.module "Assignment#initalize with ENV.POST_TO_SIS set to true",
    setup: ->
      fakeENV.setup
        POST_TO_SIS: true
        POST_TO_SIS_DEFAULT: true
    teardown: -> fakeENV.teardown()

  test "must default post_to_sis to true for a new assignment", ->
    assignment = new Assignment
    strictEqual assignment.get('post_to_sis'), true

  test "must leave a false value as is", ->
    assignment = new Assignment {post_to_sis: false}
    strictEqual assignment.get('post_to_sis'), false

  test "must leave a null value as is for an existing assignment", ->
    assignment = new Assignment {
      id: '1234',
      post_to_sis: null
    }
    strictEqual assignment.get('post_to_sis'), null

  QUnit.module "Assignment#isQuiz"

  test "returns true if record is a quiz", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'submission_types', [ 'online_quiz' ]
    equal assignment.isQuiz(), true

  test "returns false if record is not a quiz", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'submission_types', ['on_paper']
    equal assignment.isQuiz(), false

  QUnit.module "Assignment#isDiscussionTopic"

  test "returns true if record is discussion topic", ->
    assignment = new Assignment name: 'foo'
    assignment.submissionTypes( [ 'discussion_topic' ] )
    equal assignment.isDiscussionTopic(), true

  test "returns false if record is discussion topic", ->
    assignment = new Assignment name: 'foo'
    assignment.submissionTypes( ['on_paper'] )
    equal assignment.isDiscussionTopic(), false

  QUnit.module "Assignment#isExternalTool"

  test "returns true if record is external tool", ->
    assignment = new Assignment name: 'foo'
    assignment.submissionTypes( [ 'external_tool' ] )
    equal assignment.isExternalTool(), true

  test "returns false if record is not external tool", ->
    assignment = new Assignment name: 'foo'
    assignment.submissionTypes( [ 'on_paper' ] )
    equal assignment.isExternalTool(), false

  QUnit.module "Assignment#isNotGraded"

  test "returns true if record is not graded", ->
    assignment = new Assignment name: 'foo'
    assignment.submissionTypes [ 'not_graded' ]
    equal assignment.isNotGraded(), true

  test "returns false if record is graded", ->
    assignment = new Assignment name: 'foo'
    assignment.gradingType 'percent'
    assignment.submissionTypes [ 'online_url' ]
    equal assignment.isNotGraded(), false

  QUnit.module "Assignment#isAssignment"

  test "returns true if record is not quiz,ungraded,external tool, or discussion", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'submission_types', [ 'online_url' ]
    equal assignment.isAssignment(), true

  test "returns true if record has no submission types", ->
    assignment = new Assignment name: 'foo'
    equal assignment.isAssignment(), true

  test "returns false if record is quiz,ungraded, external tool, or discussion",->
    assignment = new Assignment name: 'foo'
    assignment.set 'submission_types', ['online_quiz']
    equal assignment.isAssignment(), false

  QUnit.module "Assignment#asignmentType as a setter"

  test "sets the record's submission_types to the value", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'submission_types', 'online_quiz'
    assignment.assignmentType( 'discussion_topic' )
    equal assignment.assignmentType(), 'discussion_topic'
    deepEqual assignment.get( 'submission_types' ), ['discussion_topic']

  test "when value 'assignment', sets record value to 'none'", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'submission_types', 'online_quiz'
    assignment.assignmentType( 'assignment' )
    equal assignment.assignmentType(), 'assignment'
    deepEqual assignment.get( 'submission_types' ), [ 'none' ]

  QUnit.module "Assignment#assignmentType as a getter"

  test "returns 'assignment' if not quiz, discussion topic, external tool, or ungraded", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'submission_types', [ 'on_paper' ]
    equal assignment.assignmentType(), 'assignment'

  test "returns correct assignment type if not 'assignment'", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'submission_types', ['online_quiz']
    equal assignment.assignmentType(), 'online_quiz'

  QUnit.module "Assignment#dueAt as a getter"

  test "returns record's due_at", ->
    date = Date.now()
    assignment = new Assignment name: 'foo'
    assignment.set 'due_at', date
    equal assignment.dueAt(), date

  QUnit.module "Assignment#dueAt as a setter"

  test "sets the record's due_at", ->
    date = Date.now()
    assignment = new Assignment name: 'foo'
    assignment.set 'due_at', null
    assignment.dueAt( date )
    equal assignment.dueAt(), date

  QUnit.module "Assignment#unlockAt as a getter"

  test "gets the records unlock_at", ->
    date = Date.now()
    assignment = new Assignment name: 'foo'
    assignment.set 'unlock_at', date
    equal assignment.unlockAt(), date

  QUnit.module "Assignment#unlockAt as a setter"

  test "sets the record's unlock_at", ->
    date = Date.now()
    assignment = new Assignment name: 'foo'
    assignment.set 'unlock_at', null
    assignment.unlockAt( date )
    equal assignment.unlockAt(), date

  QUnit.module "Assignment#lockAt as a getter"

  test "gets the records lock_at", ->
    date = Date.now()
    assignment = new Assignment name: 'foo'
    assignment.set 'lock_at', date
    equal assignment.lockAt(), date

  QUnit.module "Assignment#lockAt as a setter"

  test "sets the record's lock_at", ->
    date = Date.now()
    assignment = new Assignment name: 'foo'
    assignment.set 'unlock_at', null
    assignment.lockAt( date )
    equal assignment.lockAt(), date

  QUnit.module "Assignment#description as a getter"

  test "returns the record's description", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'description', 'desc'
    equal assignment.description(), 'desc'

  QUnit.module "Assignment#description as a setter"

  test "sets the record's description", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'description', null
    assignment.description('desc')
    equal assignment.description(), 'desc'
    equal assignment.get('description'), 'desc'

  QUnit.module "Assignment#dueDateRequired as a getter"

  test "returns the record's dueDateRequired", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'dueDateRequired', true
    equal assignment.dueDateRequired(), true

  QUnit.module "Assignment#dueDateRequired as a setter"

  test "sets the record's dueDateRequired", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'dueDateRequired', null
    assignment.dueDateRequired(true)
    equal assignment.dueDateRequired(), true
    equal assignment.get('dueDateRequired'), true

  QUnit.module "Assignment#name as a getter"

  test "returns the record's name", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'name', 'Todd'
    equal assignment.name(), 'Todd'

  QUnit.module "Assignment#name as a setter"

  test "sets the record's name", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'name', 'NotTodd'
    assignment.name( 'Todd' )
    equal assignment.get('name'), 'Todd'

  QUnit.module "Assignment#pointsPossible as a setter"

  test "sets the record's points_possible", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'points_possible', 0
    assignment.pointsPossible(12)
    equal assignment.pointsPossible(), 12
    equal assignment.get('points_possible'), 12

  QUnit.module "Assignment#secureParams as a getter"

  test "returns secure params if set", ->
    secure_params = 'eyJ0eXAiOiJKV1QiLCJhb.asdf232.asdf2334'
    assignment = new Assignment name: 'foo'
    assignment.set 'secure_params', secure_params
    equal assignment.secureParams(), secure_params

  QUnit.module "Assignment#assignmentGroupId as a setter"

  test "sets the record's assignment group id", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'assignment_group_id', 0
    assignment.assignmentGroupId(12)
    equal assignment.assignmentGroupId(), 12
    equal assignment.get('assignment_group_id'), 12

  QUnit.module "Assignment#canDelete",
    setup: -> fakeENV.setup({
      current_user_roles: ['teacher']
    })
    teardown: -> fakeENV.teardown()

  test "returns false if 'frozen' is true", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'frozen', true
    equal assignment.canDelete(), false

  test "returns false if 'in_closed_grading_period' is true", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'in_closed_grading_period', true
    equal assignment.canDelete(), false

  test "returns true if 'frozen' and 'in_closed_grading_period' are false", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'frozen', false
    assignment.set 'in_closed_grading_period', false
    equal assignment.canDelete(), true

  QUnit.module "Assignment#canMove as teacher",
    setup: -> fakeENV.setup({
      current_user_roles: ['teacher']
    })
    teardown: -> fakeENV.teardown()

  test "returns false if grading period is closed", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'in_closed_grading_period', true
    equal assignment.canMove(), false

  test "returns false if grading period not closed but group id is locked", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'in_closed_grading_period', false
    assignment.set 'in_closed_grading_period', ['assignment_group_id']
    equal assignment.canMove(), false

  test "returns true if grading period not closed and and group id is not locked", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'in_closed_grading_period', false
    equal assignment.canMove(), true

  QUnit.module "Assignment#canMove as admin",
    setup: -> fakeENV.setup({
      current_user_roles: ['admin']
    })
    teardown: -> fakeENV.teardown()

  test "returns true if grading period is closed", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'in_closed_grading_period', true
    equal assignment.canMove(), true

  test "returns true if grading period not closed but group id is locked", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'in_closed_grading_period', false
    assignment.set 'in_closed_grading_period', ['assignment_group_id']
    equal assignment.canMove(), true

  test "returns true if grading period not closed and and group id is not locked", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'in_closed_grading_period', false
    equal assignment.canMove(), true

  QUnit.module "Assignment#inClosedGradingPeriod as a non admin",
    setup: -> fakeENV.setup({
      current_user_roles: ['teacher']
    })
    teardown: -> fakeENV.teardown()

  test "returns the value of 'in_closed_grading_period' when isAdmin is false", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'in_closed_grading_period', true
    equal assignment.inClosedGradingPeriod(), true
    assignment.set 'in_closed_grading_period', false
    equal assignment.inClosedGradingPeriod(), false

  QUnit.module "Assignment#inClosedGradingPeriod as an admin",
    setup: -> fakeENV.setup({
      current_user_roles: ['admin']
    })
    teardown: -> fakeENV.teardown()

  test "returns true when isAdmin is true", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'in_closed_grading_period', true
    equal assignment.inClosedGradingPeriod(), false
    assignment.set 'in_closed_grading_period', false
    equal assignment.inClosedGradingPeriod(), false


  QUnit.module "Assignment#gradingType as a setter"

  test "sets the record's grading type", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'grading_type', 'points'
    assignment.gradingType 'percent'
    equal assignment.gradingType(), 'percent'
    equal assignment.get('grading_type'), 'percent'

  QUnit.module "Assignment#submissionType"

  test "returns 'none' if record's submission_types is ['none']", ->
    assignment = new Assignment name: 'foo', id: '12'
    assignment.set 'submission_types', [ 'none' ]
    equal assignment.submissionType(), 'none'

  test "returns 'on_paper' if record's submission_types includes on_paper", ->
    assignment = new Assignment name: 'foo', id: '13'
    assignment.set 'submission_types', [ 'on_paper' ]
    equal assignment.submissionType(), 'on_paper'

  test "returns online submission otherwise", ->
    assignment = new Assignment name: 'foo', id: '14'
    assignment.set 'submission_types', [ 'online_upload' ]
    equal assignment.submissionType(), 'online'

  QUnit.module "Assignment#expectsSubmission"

  test "returns false if assignment submission type is not online", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'submission_types': [ 'external_tool', 'on_paper' ]
    equal assignment.expectsSubmission(), false

  test "returns true if an assignment submission type is online", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'submission_types': [ 'online' ]
    equal assignment.expectsSubmission(), true

  QUnit.module "Assignment#allowedToSubmit"

  test "returns false if assignment is locked", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'submission_types': [ 'online' ]
    assignment.set 'locked_for_user': true
    equal assignment.allowedToSubmit(), false

  test "returns true if an assignment is not locked", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'submission_types': [ 'online' ]
    assignment.set 'locked_for_user': false
    equal assignment.allowedToSubmit(), true

  test "returns false if a submission is not expected", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'submission_types': [ 'external_tool', 'on_paper', 'attendance' ]
    equal assignment.allowedToSubmit(), false

  QUnit.module "Assignment#withoutGradedSubmission"

  test "returns false if there is a submission", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'submission': new Submission {'submission_type': 'online'}
    equal assignment.withoutGradedSubmission(), false

  test "returns true if there is no submission", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'submission': null
    equal assignment.withoutGradedSubmission(), true

  test "returns true if there is a submission, but no grade", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'submission': new Submission
    equal assignment.withoutGradedSubmission(), true

  test "returns false if there is a submission and a grade", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'submission': new Submission {'grade': 305}
    equal assignment.withoutGradedSubmission(), false

  QUnit.module "Assignment#acceptsOnlineUpload"

  test "returns true if record submission types includes online_upload", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'submission_types', [ 'online_upload' ]
    equal assignment.acceptsOnlineUpload(), true

  test "returns false if submission types doesn't include online_upload", =>
    assignment = new Assignment name: 'foo'
    assignment.set 'submission_types', []
    equal assignment.acceptsOnlineUpload(), false

  QUnit.module "Assignment#acceptsOnlineURL"

  test "returns true if assignment allows online url", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'submission_types', [ 'online_url' ]
    equal assignment.acceptsOnlineURL(), true

  test "returns false if submission types doesn't include online_url", =>
    assignment = new Assignment name: 'foo'
    assignment.set 'submission_types', []
    equal assignment.acceptsOnlineURL(), false

  QUnit.module "Assignment#acceptsMediaRecording"

  test "returns true if submission types includes media recordings", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'submission_types', [ 'media_recording' ]
    equal assignment.acceptsMediaRecording(), true

  QUnit.module "Assignment#acceptsOnlineTextEntries"

  test "returns true if submission types includes online text entry", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'submission_types', [ 'online_text_entry' ]
    equal assignment.acceptsOnlineTextEntries(), true

  QUnit.module "Assignment#peerReviews"

  test "returns the peer_reviews on the record if no args passed", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'peer_reviews', false
    equal assignment.peerReviews(), false

  test "sets the record's peer_reviews if args passed", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'peer_reviews', false
    assignment.peerReviews( true )
    equal assignment.peerReviews(), true

  QUnit.module "Assignment#automaticPeerReviews"

  test "returns the automatic_peer_reviews on the model if no args passed", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'automatic_peer_reviews', false
    equal assignment.automaticPeerReviews(), false

  test "sets the automatic_peer_reviews on the record if args passed", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'automatic_peer_reviews', false
    assignment.automaticPeerReviews( true )
    equal assignment.automaticPeerReviews(), true

  QUnit.module "Assignment#notifyOfUpdate"

  test "returns record's notifyOfUpdate if no args passed", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'notify_of_update', false
    equal assignment.notifyOfUpdate(), false

  test "sets record's notifyOfUpdate if args passed", ->
    assignment = new Assignment name: 'foo'
    assignment.notifyOfUpdate( false )
    equal assignment.notifyOfUpdate(), false

  QUnit.module "Assignment#multipleDueDates"

  test "checks for multiple due dates from assignment overrides", ->
    assignment = new Assignment all_dates: [{title: "Winter"}, {title: "Summer"}]
    ok assignment.multipleDueDates()

  test "checks for no multiple due dates from assignment overrides", ->
    assignment = new Assignment
    ok !assignment.multipleDueDates()

  QUnit.module "Assignment#allDates"

  test "gets the due dates from the assignment overrides", ->
    dueAt = new Date("2013-08-20T11:13:00")
    dates = [
      new DateGroup due_at: dueAt, title: "Everyone"
    ]
    assignment = new Assignment all_dates: dates
    allDates = assignment.allDates()
    first    = allDates[0]

    equal first.dueAt+"", dueAt+""
    equal first.dueFor,   "Everyone"

  test "gets empty due dates when there are no dates", ->
    assignment = new Assignment
    deepEqual assignment.allDates(), []

  QUnit.module "Assignment#inGradingPeriod",
    setup: ->
      @gradingPeriod =
        id: "1"
        title: "Fall"
        startDate: new Date("2013-07-01T11:13:00")
        endDate: new Date("2013-10-01T11:13:00")
        closeDate: new Date("2013-10-05T11:13:00")
        isLast: true
        isClosed: true

      @dateInPeriod = new Date("2013-08-20T11:13:00")
      @dateOutsidePeriod = new Date("2013-01-20T11:13:00")

  test "returns true if the assignment has a due_at in the given period", ->
    assignment = new Assignment
    assignment.set 'due_at', @dateInPeriod
    equal assignment.inGradingPeriod(@gradingPeriod), true

  test "returns false if the assignment has a due_at outside the given period", ->
    assignment = new Assignment
    assignment.set 'due_at', @dateOutsidePeriod
    equal assignment.inGradingPeriod(@gradingPeriod), false

  test "returns true if the assignment has a date group in the given period", ->
    dates = [new DateGroup(due_at: @dateInPeriod, title: "Everyone")]
    assignment = new Assignment all_dates: dates
    equal assignment.inGradingPeriod(@gradingPeriod), true

  test "returns false if the assignment does not have a date group in the given period", ->
    dates = [new DateGroup(due_at: @dateOutsidePeriod, title: "Everyone")]
    assignment = new Assignment all_dates: dates
    equal assignment.inGradingPeriod(@gradingPeriod), false

  QUnit.module "Assignment#singleSectionDueDate",
    setup: -> fakeENV.setup()
    teardown: -> fakeENV.teardown()

  test "gets the due date for section instead of null", ->
    dueAt = new Date("2013-11-27T11:01:00Z")
    assignment = new Assignment all_dates: [
      {due_at: null, title: "Everyone"},
      {due_at: dueAt, title: "Summer"}
    ]
    @stub assignment, "multipleDueDates", -> false
    equal assignment.singleSectionDueDate(), dueAt.toISOString()

  test "returns due_at when only one date/section are present", ->
    date = Date.now()
    assignment = new Assignment name: 'Taco party!'
    assignment.set 'due_at', date
    equal assignment.singleSectionDueDate(), assignment.dueAt()

    # For students
    ENV.PERMISSIONS = { manage: false }
    equal assignment.singleSectionDueDate(), assignment.dueAt()
    ENV.PERMISSIONS = {}

  QUnit.module "Assignment#omitFromFinalGrade"

  test "gets the record's omit_from_final_grade boolean", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'omit_from_final_grade', true
    ok assignment.omitFromFinalGrade()

  test "sets the record's omit_from_final_grade boolean if args passed", ->
    assignment = new Assignment name: 'foo'
    assignment.omitFromFinalGrade( true )
    ok assignment.omitFromFinalGrade()

  QUnit.module "Assignment#toView",
    setup: -> fakeENV.setup({
      current_user_roles: ['teacher']
    })
    teardown: -> fakeENV.teardown()

  test "returns the assignment's name", ->
    assignment = new Assignment name: 'foo'
    assignment.name 'Todd'
    json = assignment.toView()
    equal json.name, 'Todd'

  test "returns the assignment's dueAt", ->
    date = Date.now()
    assignment = new Assignment name: 'foo'
    assignment.dueAt date
    json = assignment.toView()
    equal json.dueAt, date

  test "includes the assignment's description", ->
    description = "Yo yo fasho"
    assignment = new Assignment name: 'foo'
    assignment.description description
    json = assignment.toView()
    equal json.description, description

  test "includes the assignment's dueDateRequired", ->
    dueDateRequired = false
    assignment = new Assignment name: 'foo'
    assignment.dueDateRequired dueDateRequired
    json = assignment.toView()
    equal json.dueDateRequired, dueDateRequired

  test "returns assignment's points possible", ->
    pointsPossible = 12
    assignment = new Assignment name: 'foo'
    assignment.pointsPossible pointsPossible
    json = assignment.toView()
    equal json.pointsPossible, pointsPossible

  test "returns assignment's lockAt", ->
    lockAt = Date.now()
    assignment = new Assignment name: 'foo'
    assignment.lockAt lockAt
    json = assignment.toView()
    equal json.lockAt, lockAt

  test "includes assignment's unlockAt", ->
    unlockAt = Date.now()
    assignment = new Assignment name: 'foo'
    assignment.unlockAt unlockAt
    json = assignment.toView()
    equal json.unlockAt, unlockAt

  test "includes assignment's gradingType", ->
    gradingType = 'percent'
    assignment = new Assignment name: 'foo'
    assignment.gradingType gradingType
    json = assignment.toView()
    equal json.gradingType, gradingType

  test "includes assignment's notifyOfUpdate", ->
    notifyOfUpdate = false
    assignment = new Assignment name: 'foo'
    assignment.notifyOfUpdate notifyOfUpdate
    json = assignment.toView()
    equal json.notifyOfUpdate, notifyOfUpdate

  test "includes assignment's peerReviews", ->
    peerReviews = false
    assignment = new Assignment name: 'foo'
    assignment.peerReviews peerReviews
    json = assignment.toView()
    equal json.peerReviews, peerReviews

  test "includes assignment's automaticPeerReviews value", ->
    autoPeerReviews = false
    assignment = new Assignment name: 'foo'
    assignment.automaticPeerReviews autoPeerReviews
    json = assignment.toView()
    equal json.automaticPeerReviews, autoPeerReviews

  test "includes boolean indicating whether or not assignment accepts uploads",->
    assignment = new Assignment name: 'foo'
    assignment.set 'submission_types', [ 'online_upload' ]
    json = assignment.toView()
    equal json.acceptsOnlineUpload, true

  test "includes whether or not assignment accepts media recordings", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'submission_types', [ 'media_recording' ]
    json = assignment.toView()
    equal json.acceptsMediaRecording, true

  test "includes submissionType", ->
    assignment = new Assignment name: 'foo', id: '16'
    assignment.set 'submission_types', [ 'on_paper' ]
    json = assignment.toView()
    equal json.submissionType, 'on_paper'

  test "includes acceptsOnlineTextEntries", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'submission_types', [ 'online_text_entry' ]
    json = assignment.toView()
    equal json.acceptsOnlineTextEntries, true

  test "includes acceptsOnlineURL", ->
    assignment = new Assignment name: 'foo'
    assignment.set 'submission_types', [ 'online_url' ]
    json = assignment.toView()
    equal json.acceptsOnlineURL, true

  test "includes allowedExtensions", ->
    assignment = new Assignment name: 'foo'
    assignment.allowedExtensions []
    json = assignment.toView()
    deepEqual json.allowedExtensions, []

  test "includes htmlUrl", ->
    assignment = new Assignment html_url: 'http://example.com/assignments/1'
    json = assignment.toView()
    equal json.htmlUrl, 'http://example.com/assignments/1'

  test "includes htmlEditUrl", ->
    assignment = new Assignment html_url: 'http://example.com/assignments/1'
    json = assignment.toView()
    equal json.htmlEditUrl, 'http://example.com/assignments/1/edit'

  test "includes multipleDueDates", ->
    assignment = new Assignment all_dates: [{title: "Summer"}, {title: "Winter"}]
    json = assignment.toView()
    equal json.multipleDueDates, true

  test "includes allDates", ->
    assignment = new Assignment all_dates: [{title: "Summer"}, {title: "Winter"}]
    json = assignment.toView()
    equal json.allDates.length, 2

  test "includes singleSectionDueDate", ->
    dueAt = new Date("2013-11-27T11:01:00Z")
    assignment = new Assignment all_dates: [
      {due_at: null, title: "Everyone"},
      {due_at: dueAt, title: "Summer"}
    ]
    @stub assignment, "multipleDueDates", -> false
    json = assignment.toView()
    equal json.singleSectionDueDate, dueAt.toISOString()

  test "includes fields for isPage", ->
    assignment = new Assignment("submission_types":["wiki_page"])
    json = assignment.toView()
    notOk json.hasDueDate
    notOk json.hasPointsPossible

  test "includes fields for isQuiz", ->
    assignment = new Assignment("submission_types":["online_quiz"])
    json = assignment.toView()
    ok json.hasDueDate
    notOk json.hasPointsPossible

  test "returns omitFromFinalGrade", ->
    assignment = new Assignment name: 'foo'
    assignment.omitFromFinalGrade true
    json = assignment.toView()
    ok json.omitFromFinalGrade

  QUnit.module "Assignment#isQuizLTIAssignment"

  test "returns true if record uses quizzes 2", ->
    assignment = new Assignment name: 'foo', is_quiz_lti_assignment: true
    equal assignment.isQuizLTIAssignment(), true

  test "returns false if record does not use quizzes 2", ->
    assignment = new Assignment name: 'foo', is_quiz_lti_assignment: false
    equal assignment.isQuizLTIAssignment(), false

  QUnit.module "Assignment#canFreeze"

  test "returns true if record is not frozen", ->
    assignment = new Assignment name: 'foo', frozen_attributes: []
    equal assignment.canFreeze(), true

  test "returns false if record is frozen", ->
    assignment = new Assignment name: 'foo', frozen_attributes: [], frozen: true
    equal assignment.canFreeze(), false

  test "returns false if record uses quizzes 2", ->
    assignment = new Assignment name: 'foo', frozen_attributes: []
    @stub assignment, "isQuizLTIAssignment", -> true
    equal assignment.canFreeze(), false
