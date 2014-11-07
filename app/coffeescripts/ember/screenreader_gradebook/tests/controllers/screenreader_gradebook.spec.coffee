define [
  'jquery'
  'underscore'
  '../start_app'
  'ember'
  '../shared_ajax_fixtures'
  '../../controllers/screenreader_gradebook_controller'
  'compiled/userSettings'
  'vendor/jquery.ba-tinypubsub'
], ($, _, startApp, Ember, fixtures, SRGBController, userSettings) ->

  App = null
  originalIsDraft = null
  originalWeightingScheme = null

  clone = (obj) ->
    Em.copy obj, true


  fixtures.create()
  setup = (isDraftState=false, sortOrder='assignment_group') ->
    window.ENV.GRADEBOOK_OPTIONS.draft_state_enabled = isDraftState
    originalWeightingScheme =  window.ENV.GRADEBOOK_OPTIONS.group_weighting_scheme
    @contextGetStub = sinon.stub(userSettings, 'contextGet')
    @contextSetStub = sinon.stub(userSettings, 'contextSet')
    @contextGetStub.withArgs('sort_grade_columns_by').returns({sortType: sortOrder})
    @contextSetStub.returns({sortType: sortOrder})
    App = startApp()
    Ember.run =>
      @srgb = SRGBController.create()
      @srgb.set('model', {
        enrollments: Ember.ArrayProxy.create(content: clone fixtures.students)
        assignment_groups: Ember.ArrayProxy.create(content: clone fixtures.assignment_groups)
        submissions: Ember.ArrayProxy.create(content: [])
        sections: Ember.ArrayProxy.create(content: clone fixtures.sections)
        outcomes: Ember.ArrayProxy.create(content: clone fixtures.outcomes)
        outcome_rollups: Ember.ArrayProxy.create(content: clone fixtures.outcome_rollups)
      })

  teardown = ->
    window.ENV.GRADEBOOK_OPTIONS.draft_state_enabled = false
    window.ENV.GRADEBOOK_OPTIONS.group_weighting_scheme = originalWeightingScheme
    @contextGetStub.restore()
    @contextSetStub.restore()
    Ember.run App, 'destroy'

  module 'screenreader_gradebook_controller',
    setup: ->
      setup.call this
    teardown: ->
      teardown.call this


  test 'calculates students properly', ->
    equal @srgb.get('students.length'), 10
    equal @srgb.get('students.firstObject').name, fixtures.students[0].user.name

  test 'calculates assignments properly', ->
    equal @srgb.get('assignments.length'), 7
    ok !@srgb.get('assignments').findBy('name', 'Not Graded')
    equal @srgb.get('assignments.firstObject').name, fixtures.assignment_groups[0].assignments[0].name

  test 'calculates outcomes properly', ->
    equal @srgb.get('outcomes.length'), 2
    equal @srgb.get('outcomes.firstObject').title, fixtures.outcomes[0].title

  test 'studentsHash returns the expected hash', ->
    _.each @srgb.studentsHash(), (obj) =>
      strictEqual @srgb.get('students').findBy('id', obj.id), obj

  test 'assignmentGroupsHash retuns the expected hash', ->
    _.each @srgb.assignmentGroupsHash(), (obj) =>
      strictEqual @srgb.get('assignment_groups').findBy('id', obj.id), obj

  test 'student objects have isLoaded flag set to true once submissions are loaded', ->
    @srgb.get('students').forEach (s) ->
      equal Ember.get(s, 'isLoaded'), true

  test 'displayName is hiddenName when hideStudentNames is true', ->
    @srgb.set('hideStudentNames', true)
    equal @srgb.get('displayName'), "hiddenName"
    @srgb.set('hideStudentNames', false)
    equal @srgb.get('displayName'), "name"

  test 'displayPointTotals is false when groups are weighted even if showTotalAsPoints is true', ->
    Ember.run =>
      @srgb.set('showTotalAsPoints', true)
      @srgb.set('groupsAreWeighted', true)
      equal @srgb.get('displayPointTotals'), false

  test 'displayPointTotals is toggled by showTotalAsPoints when groups are unweighted', ->
    Ember.run =>
      @srgb.set('groupsAreWeighted', false)
      @srgb.set('showTotalAsPoints', true)
      equal @srgb.get('displayPointTotals'), true
      @srgb.set('showTotalAsPoints', false)
      equal @srgb.get('displayPointTotals'), false

  test 'updateSubmission attaches the submission to the student', ->
    student = clone fixtures.students[0].user
    submission = clone fixtures.submissions[student.id].submissions[0]

    @srgb.updateSubmission submission, student
    strictEqual student["assignment_#{submission.assignment_id}"], submission

  test 'studentsInSelectedSection is the same as students when selectedSection is null', ->
    ok (!@srgb.get('selectedSection'))
    deepEqual @srgb.get('students'), @srgb.get('studentsInSelectedSection')

  test 'selecting a section filters students properly', ->
    Ember.run =>
      @srgb.set('selectedSection', @srgb.get('sections.lastObject'))
    equal @srgb.get('studentsInSelectedSection.length'), 6
    equal @srgb.get('studentsInSelectedSection.firstObject').name, 'Buffy'

  test 'sorting assignments by position', ->
    Ember.run =>
      @srgb.set('assignmentSort', @srgb.get('assignmentSortOptions').findBy('value', 'assignment_group'))
    equal @srgb.get('assignments.firstObject.name'), 'Z Eats Soup'
    equal @srgb.get('assignments.lastObject.name'), 'Da Fish and Chips!'

  test 'updates assignment groups and weightingScheme when event is triggered', ->
    window.ENV.GRADEBOOK_OPTIONS.group_weighting_scheme = 'whoa'
    Ember.run =>
      $.publish('assignment_group_weights_changed', assignmentGroups: Ember.copy(fixtures.assignment_groups, true).slice(0,1))

    equal @srgb.get('weightingScheme'), 'whoa', 'weightingScheme was updated'
    equal @srgb.get('assignment_groups.length'), 1, 'assignment_groups was updated'

  test 'updates assignment_visibility on an assignment', ->
    assignments = @srgb.get('assignments')
    assgn = assignments.objectAt(2)
    @srgb.updateAssignmentVisibilities(assgn, 3)
    ok !assgn.assignment_visibility.contains('3')

  test 'studentsThatCanSeeAssignment doesnt return all students', ->
    assgn = @srgb.get('assignments.firstObject')
    students = @srgb.studentsThatCanSeeAssignment(assgn)
    ids = Object.keys(students)
    equal ids.length, 1
    equal ids[0], '1'

  # Hacky setup and teardown (thanks, local storage). I invite you to make this better.
  module 'screenreader_gradebook_controller: sorting alpha',
    setup: ->
      setup.call this, false, 'alpha'
    teardown: ->
      teardown.call this

  test 'sorting assignments alphabetically', ->
    Ember.run =>
      @srgb.set('assignmentSort', @srgb.get('assignmentSortOptions').findBy('value', 'alpha'))
    equal @srgb.get('assignments.firstObject.name'), 'Apples are good'
    equal @srgb.get('assignments.lastObject.name'), 'Z Eats Soup'


  # Hacky setup and teardown (thanks, local storage). I invite you to make this better.
  module 'screenreader_gradebook_controller: sorting due_date',
    setup: ->
      setup.call this, false, 'due_date'
    teardown: ->
      teardown.call this

  test 'sorting assignments by due date', ->
    Ember.run =>
      @srgb.set('assignmentSort', @srgb.get('assignmentSortOptions').findBy('value', 'due_date'))
    equal @srgb.get('assignments.firstObject.name'), 'Can You Eat Just One?'
    equal @srgb.get('assignments.lastObject.name'), 'Drink Water'


  module 'screenreader_gradebook_controller: with selected student',
    setup: ->
      setup.call this
      Ember.run =>
        student = @srgb.get('students.firstObject')
        @srgb.set('selectedStudent', student)
    teardown: ->
      teardown.call this

  test 'selectedSubmission should be null when just selectedStudent is set', ->
    strictEqual @srgb.get('selectedSubmission'), null

  module 'screenreader_gradebook_controller: with selected student, assignment, and outcome',
    setup: ->
      setup.call this
      Ember.run =>
        @student = @srgb.get('students.firstObject')
        @assignment = @srgb.get('assignments.firstObject')
        @outcome = @srgb.get('outcomes.firstObject')
        @srgb.set('selectedStudent', @student)
        @srgb.set('selectedAssignment', @assignment)
        @srgb.set('selectedOutcome', @outcome)

    teardown: ->
      teardown.call this

  test 'assignmentDetails is computed properly', ->
    ad = @srgb.get('assignmentDetails')
    selectedAssignment = @srgb.get('selectedAssignment')
    strictEqual ad.assignment, selectedAssignment
    strictEqual ad.cnt, 1

  test 'outcomeDetails is computed properly', ->
    od = @srgb.get('outcomeDetails')
    selectedOutcome = @srgb.get('selectedOutcome')
    strictEqual od.cnt, 1

  test 'selectedSubmission is computed properly', ->
    selectedSubmission = @srgb.get('selectedSubmission')
    sub = _.find(fixtures.submissions, (s) => s.user_id == @student.id)
    submission = _.find(sub.submissions, (s) => s.assignment_id == @assignment.id)
    _.each submission, (val, key) =>
      equal selectedSubmission[key], val, "#{key} is the expected value on selectedSubmission"

  module 'screenreader_gradebook_controller: with selected assignment',
    setup: ->
      setup.call this
      @assignment = @srgb.get('assignments.firstObject')
      Ember.run =>
        @srgb.set('selectedAssignment', @assignment)

    teardown: ->
      @contextGetStub.restore()
      @contextSetStub.restore()
      Ember.run App, 'destroy'

  test 'gets the submission types', ->
    equal @srgb.get('assignmentSubmissionTypes'), 'None'
    Ember.run =>
      assignments = @srgb.get('assignments')
      @srgb.set('selectedAssignment', assignments.objectAt(1))
    equal @srgb.get('assignmentSubmissionTypes'), 'Online URL, Online text entry'

  module 'screenreader_gradebook_controller:draftState',
    setup: ->
      setup.call this, true
      Em.run =>
        @srgb.get('assignment_groups').pushObject
          id: '100'
          name: 'Silent Assignments'
          position: 2
          assignments: [
            {
              id: '21'
              name: 'Unpublished Assignment'
              points_possible: 10
              grading_type: "percent"
              submission_types: ["none"]
              due_at: null
              position: 6
              assignment_group_id:'4'
              published: false
            }
          ]

    teardown: ->
      teardown.call this

  test 'calculates assignments properly', ->
    equal @srgb.get('assignments.length'), 7
    ok !@srgb.get('assignments').findBy('name', 'Unpublished Assignment')


  calc_stub = {
    group_sums: [
      {
        final:
          possible: 100
          score: 50
          submission_count: 10
          weight: 50
          submissions: []
        current:
          possible: 100
          score: 20
          submission_count: 5
          weight: 50
          submissions:[]
        group:
          id: "1"
      }
    ]
    final:
      possible: 100
      score: 90
    current:
      possible: 88
      score: 70
  }


  calc_stub_with_0_possible = {
    group_sums: [
      {
        final:
          possible: 0
          score: 50
          submission_count: 10
          weight: 50
          submissions: []
        current:
          possible: 0
          score: 20
          submission_count: 5
          weight: 50
          submissions:[]
        group:
          id: "1"
      }
    ]
    final:
      possible: 0
      score: 0
    current:
      possible: 0
      score: 0
  }

  calculationSetup = (calculationStub = calc_stub) ->
    App = startApp()
    Ember.run =>
      @srgb = SRGBController.create()
      @srgb.reopen
        calculate: ->
          calculationStub

      @srgb.set('model', {
        enrollments: Ember.ArrayProxy.create(content: clone fixtures.students)
        assignment_groups: Ember.ArrayProxy.create(content: clone fixtures.assignment_groups)
        submissions: Ember.ArrayProxy.create(content: [])
        sections: Ember.ArrayProxy.create(content: clone fixtures.sections)
      })

  module 'screenreader_gradebook_controller: grade calc',
    setup: ->
      calculationSetup.call this

  test 'calculates final grade', ->
    equal @srgb.get('students.firstObject.total_percent'), 79.5

  module 'grade calc with 0s',
    setup: ->
      calculationSetup.call this, calc_stub_with_0_possible

  test 'calculates final grade', ->
    equal @srgb.get('students.firstObject.total_percent'), 0


  module 'screenreader_gradebook_controller: notes computed props',
    setup: ->
      ENV.GRADEBOOK_OPTIONS.custom_column_url = '/here/is/an/:id'
      ENV.GRADEBOOK_OPTIONS.teacher_notes = id:'42'
      @server = sinon.fakeServer.create()
      setup.call this
      Ember.run =>
        #@srgb.set('custom_columns', [{teacher_notes: true, id: '42'}])
        @srgb.reopen
          updateOrCreateNotesColumn: ->
    teardown: ->
      ENV.GRADEBOOK_OPTIONS.custom_column_url = null
      ENV.GRADEBOOK_OPTIONS.teacher_notes = null
      @server.restore()
      teardown.call this

  test 'computes showNotesColumn correctly', ->
    ENV.GRADEBOOK_OPTIONS.teacher_notes =
      hidden: false
    equal @srgb.get('showNotesColumn'), true

    ENV.GRADEBOOK_OPTIONS.teacher_notes =
      hidden: true
    equal @srgb.get('showNotesColumn'), false

    ENV.GRADEBOOK_OPTIONS.teacher_notes = null
    equal @srgb.get('showNotesColumn'), false

  test 'shouldCreateNotes, no notes in ENV', ->
    ENV.GRADEBOOK_OPTIONS.teacher_notes = null
    Ember.run =>
      @srgb.set('showNotesColumn', true)
    equal @srgb.get('shouldCreateNotes'), true, 'true if no teacher_notes and showNotesColumns is true'

  test 'shouldCreateNotes, notes in ENV, hidden', ->
    ENV.GRADEBOOK_OPTIONS.teacher_notes =
      hidden: true
    Ember.run =>
      @srgb.set('showNotesColumn', true)
    actual = @srgb.get('shouldCreateNotes')
    equal actual, false, 'does not create if there is a teacher_notes object in the ENV'

  test 'shouldCreateNotes, notes in ENV, shown', ->
    ENV.GRADEBOOK_OPTIONS.teacher_notes =
      hidden: false
    Ember.run =>
      @srgb.set('showNotesColumn', true)
    equal @srgb.get('shouldCreateNotes'), false, 'does not create if there is a teacher_notes object in the ENV'

  test 'notesURL, no notes object in ENV', ->
    Ember.run =>
      @srgb.set('shouldCreateNotes', true)
    equal @srgb.get('notesURL'), ENV.GRADEBOOK_OPTIONS.custom_columns_url, 'computes properly when creating'
    Ember.run =>
      @srgb.set('shouldCreateNotes', false)
    equal @srgb.get('notesURL'), '/here/is/an/42', 'computes properly when showing'

  test 'notesParams', ->
    Ember.run =>
      @srgb.set('showNotesColumn', true)
      @srgb.set('shouldCreateNotes', false)
    deepEqual @srgb.get('notesParams'), "column[hidden]": false

    Ember.run =>
      @srgb.set('showNotesColumn', false)
      @srgb.set('shouldCreateNotes', false)
    deepEqual @srgb.get('notesParams'), "column[hidden]": true

    Ember.run =>
      @srgb.set('showNotesColumn', true)
      @srgb.set('shouldCreateNotes', true)
    deepEqual @srgb.get('notesParams'),
        "column[title]": "Notes"
        "column[position]": 1
        "column[teacher_notes]": true

  test 'notesVerb', ->
    Ember.run =>
      @srgb.set('shouldCreateNotes', true)
    equal @srgb.get('notesVerb'), 'POST'

    Ember.run =>
      @srgb.set('shouldCreateNotes', false)
    equal @srgb.get('notesVerb'), 'PUT'

  module 'screenreader_gradebook_controller:invalidGroups',
    setup: ->
      setup.call this, true
      Em.run =>
        @srgb.set('assignment_groups',Ember.ArrayProxy.create(content: clone fixtures.assignment_groups))
    teardown: ->
      teardown.call this

  test 'calculates invalidGroupsWarningPhrases properly', ->
    equal @srgb.get('invalidGroupsWarningPhrases'), "Note: Score does not include assignments from the group Invalid AG because it has no points possible."

  test 'sets showInvalidGroupWarning to false if groups are not weighted', ->
    Ember.run =>
      @srgb.set('weightingScheme', "equal")
      equal @srgb.get('showInvalidGroupWarning'), false
      @srgb.set('weightingScheme', "percent")
      equal @srgb.get('showInvalidGroupWarning'), true


  module 'screenreader_gradebook_controller: differentiated assignments',
    setup: ->
      setup.call this, true
    teardown: ->
      teardown.call this

  test 'selectedSubmissionHidden is false when students have visibility', ->
    student = @srgb.get('students.firstObject')
    assignment = @srgb.get('assignments.firstObject')

    Ember.run =>
      @srgb.set('selectedAssignment', assignment)
      @srgb.set('selectedStudent', student)
      equal @srgb.get('selectedSubmissionHidden'), false

  test 'selectedSubmissionHidden is true when students dont have visibility', ->
    student = @srgb.get('students').objectAt(2)
    assignment = @srgb.get('assignments.firstObject')

    Ember.run =>
      @srgb.set('selectedAssignment', assignment)
      @srgb.set('selectedStudent', student)
      equal @srgb.get('selectedSubmissionHidden'), true


