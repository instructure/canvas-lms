define [
  'compiled/models/Assignment2'
  'compiled/views/FullAssignmentView'
  'underscore'
], (Assignment, EditAssignmentView, _ ) ->

  window.ENV.KALTURA_ENABLED = true

  visible = ( $el ) ->
    $el.is(':visible')

  module "FullAssignmentView"

  module "FullAssignmentView.render"

  module "FullAssignmentView on grading type field change"

  test "hides submission type options if grading type is 'Not Graded'", ->
    assignment = new Assignment()
    assignmentView = new EditAssignmentView( el: '#fixtures', model: assignment )
    assignmentView.render()
    assignmentView.$gradingType.val( 'not_graded' ).trigger( 'change' )
    ok !visible( assignmentView.$submissionTypesArea )

  test "shows submission types options if grading type not 'Not Graded'", ->
    assignment = new Assignment()
    assignmentView = new EditAssignmentView( el: '#fixtures', model: assignment )
    assignmentView.render()
    assignmentView.$gradingType.val( 'not_graded' ).trigger( 'change' )
    assignmentView.$gradingType.val( 'percent' ).trigger( 'change' )
    ok visible( assignmentView.$submissionTypesArea )

  module "FullAssignmentView on SubmissionType change"

  test "hides online submission types if new value isn't 'online'", ->
    assignment = new Assignment()
    assignmentView = new EditAssignmentView(el: '#fixtures', model: assignment)
    assignmentView.render()
    assignmentView.$submissionType.val( 'none' ).trigger( 'change' )
    ok !visible( assignmentView.$onlineSubmissionTypes )

  test "shows online submission types if new value is 'online'", ->
    assignment = new Assignment()
    assignmentView = new EditAssignmentView(el: '#fixtures', model: assignment)
    assignmentView.render()
    assignmentView.$submissionType.val( 'none' ).trigger( 'change' )
    assignmentView.$submissionType.val( 'online' ).trigger( 'change' )
    ok visible( assignmentView.$onlineSubmissionTypes )

  module "FullAssignmentView on submit"

  test ""

  test "calls save on the assignment", ->
    assignment = new Assignment()
    assignmentView = new EditAssignmentView(el: '#fixtures', model: assignment)
    assignmentView.render()
    assignmentView.$gradingType.val( 'not_graded' ).trigger( 'change' )
    sinon.stub( assignment, 'save' )
    assignmentView.$el.submit()
    ok( assignment.save.called )

  module "FullAssignmentView on submit when grading type is not graded"

  test "sets submission_types to 'not_graded'", ->
    assignment = new Assignment( name: 'foo' )
    assignmentView = new EditAssignmentView(el: '#fixtures', model: assignment)
    assignmentView.render()
    assignmentView.$gradingType.val( 'not_graded' ).trigger( 'change' )
    assignmentView.$el.submit()
    deepEqual assignment.submissionTypes(), [ 'not_graded' ]

  module "FullAssignmentView on submit when no online submission type checked"

  test "alerts the user they should pick at least one type", ->
    assignment = new Assignment( name: 'foo' )
    assignmentView = new EditAssignmentView( el: '#fixtures', model: assignment)
    assignmentView.render()
    errorBoxStub = sinon.stub assignmentView.$submissionType, 'errorBox'
    assignmentSaveStub = sinon.stub assignment, 'save'
    assignmentView.$submissionType.val( 'online' ).trigger( 'change' )
    assignmentView.$el.submit()
    ok errorBoxStub.called,'user not alerted'
    ok !assignmentSaveStub.called, 'assignment incorrectly saved'

  module "FullAssignmentView on submit erorr validations"

  test "alerts the user that title cannot be empty and doesn't save", ->
    assignment = new Assignment
    assignmentView = new EditAssignmentView(el: '#fixtures', model: assignment)
    assignmentView.render()
    sinon.stub assignmentView.$name, 'errorBox'
    sinon.stub assignmentView, 'displayErrors'
    assignmentView.$name.val( '' ).trigger 'change'
    assignmentView.$el.submit()
    ok( assignmentView.displayErrors.called )

  module "FullAssignmentView#displayError"

  test "alerts the user if inputted assignment name is empty", ->
    assignment = new Assignment name: 'foo'
    assignmentView = new EditAssignmentView(el: '#fixtures', model: assignment)
    assignmentView.render()
    sinon.stub assignmentView.$name, 'errorBox'
    assignmentView.$name.val( '' ).trigger 'change'
    assignmentView.$el.submit()
    ok( assignmentView.$name.errorBox.called )

