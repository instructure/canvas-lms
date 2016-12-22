define [
  'jquery'
  'underscore'
  'ic-ajax'
  '../start_app'
  'ember'
  '../shared_ajax_fixtures'
  '../../controllers/screenreader_gradebook_controller'
  'compiled/userSettings'
  'vendor/jquery.ba-tinypubsub'
], ($, _, ajax, startApp, Ember, fixtures, SRGBController, userSettings) ->

  workAroundRaceCondition = ->
    ajax.request()

  App = null
  originalIsDraft = null

  clone = (obj) ->
    Ember.copy obj, true

  setup = (isDraftState=false, sortOrder='assignment_group') ->
    fixtures.create()
    @contextGetStub = sinon.stub(userSettings, 'contextGet')
    @contextSetStub = sinon.stub(userSettings, 'contextSet')
    @contextGetStub.withArgs('sort_grade_columns_by').returns({sortType: sortOrder})
    @contextSetStub.returns({sortType: sortOrder})
    App = startApp()
    Ember.run =>
      @srgb = SRGBController.create()
      effectiveDueDates = Ember.ObjectProxy.create(content: clone fixtures.effectiveDueDates)
      Ember.setProperties effectiveDueDates, { isLoaded: true }
      @srgb.set('model', {
        enrollments: Ember.ArrayProxy.create(content: clone fixtures.students)
        assignment_groups: Ember.ArrayProxy.create(content: [])
        submissions: Ember.ArrayProxy.create(content: [])
        sections: Ember.ArrayProxy.create(content: clone fixtures.sections)
        outcomes: Ember.ArrayProxy.create(content: clone fixtures.outcomes)
        outcome_rollups: Ember.ArrayProxy.create(content: clone fixtures.outcome_rollups)
        effectiveDueDates: effectiveDueDates
      })

  teardown = ->
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
    workAroundRaceCondition().then =>
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
    workAroundRaceCondition().then =>
      _.each @srgb.assignmentGroupsHash(), (obj) =>
        strictEqual @srgb.get('assignment_groups').findBy('id', obj.id), obj

  test 'student objects have isLoaded flag set to true once submissions are loaded', ->
    workAroundRaceCondition().then =>
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
    workAroundRaceCondition().then =>
      Ember.run =>
        @srgb.set('assignmentSort', @srgb.get('assignmentSortOptions').findBy('value', 'assignment_group'))
      equal @srgb.get('assignments.firstObject.name'), 'Z Eats Soup'
      equal @srgb.get('assignments.lastObject.name'), 'Da Fish and Chips!'

  test 'updates assignment_visibility on an assignment', ->
    workAroundRaceCondition().then =>
      assignments = @srgb.get('assignments')
      assgn = assignments.objectAt(2)
      @srgb.updateAssignmentVisibilities(assgn, '3')
      ok !assgn.assignment_visibility.contains('3')

  test 'studentsThatCanSeeAssignment doesnt return all students', ->
    workAroundRaceCondition().then =>
      assgn = @srgb.get('assignments.firstObject')
      students = @srgb.studentsThatCanSeeAssignment(assgn)
      ids = Object.keys(students)
      equal ids.length, 1
      equal ids[0], '1'

  test 'sorting assignments alphabetically', ->
    workAroundRaceCondition().then =>
      Ember.run =>
        @srgb.set('assignmentSort', @srgb.get('assignmentSortOptions').findBy('value', 'alpha'))
      equal @srgb.get('assignments.firstObject.name'), 'Apples are good'
      equal @srgb.get('assignments.lastObject.name'), 'Z Eats Soup'

  test 'sorting assignments by due date', ->
    workAroundRaceCondition().then =>
      Ember.run =>
        @srgb.set('assignmentSort', @srgb.get('assignmentSortOptions').findBy('value', 'due_date'))
      equal @srgb.get('assignments.firstObject.name'), 'Can You Eat Just One?'
      equal @srgb.get('assignments.lastObject.name'), 'Drink Water'

  module "#submissionsForStudent",
    setupThis: (options = {}) ->
      effectiveDueDates = Ember.ObjectProxy.create(
        content: {
          1: { 1: { grading_period_id: "1" } },
          2: { 1: { grading_period_id: "2" } }
        }
      )

      defaults = {
        mgpEnabled: false,
        "selectedGradingPeriod.id": null,
        effectiveDueDates
      }
      self = _.defaults options, defaults
      self.get = (attribute) -> self[attribute]
      self

    setup: ->
      @student =
        id: "1"
        assignment_1: { assignment_id: "1", user_id: "1", name: "yolo" }
        assignment_2: { assignment_id: "2", user_id: "1", name: "froyo" }

      setup.call this

    teardown: ->
      teardown.call this

  test "returns all submissions for the student (multiple grading periods disabled)", ->
    self = @setupThis()
    submissions = @srgb.submissionsForStudent.call(self, @student)
    propEqual _.pluck(submissions, "assignment_id"), ["1", "2"]

  test "returns all submissions if 'All Grading Periods' is selected", ->
    self = @setupThis(
      mgpEnabled: true,
      "selectedGradingPeriod.id": "0",
    )
    submissions = @srgb.submissionsForStudent.call(self, @student)
    propEqual _.pluck(submissions, "assignment_id"), ["1", "2"]

  test "only returns submissions due for the student in the selected grading period", ->
    self = @setupThis(
      mgpEnabled: true,
      "selectedGradingPeriod.id": "2"
    )
    submissions = @srgb.submissionsForStudent.call(self, @student)
    propEqual _.pluck(submissions, "assignment_id"), ["2"]


  module 'screenreader_gradebook_controller: with selected student',
    setup: ->
      setup.call this
      @completeSetup = =>
        workAroundRaceCondition().then =>
          Ember.run =>
            @srgb.set('selectedGradingPeriod', { id: '3' })
            @srgb.set('assignment_groups', Ember.ArrayProxy.create(content: clone fixtures.assignment_groups))
            @srgb.set('assignment_groups.isLoaded', true)
            student = @srgb.get('students.firstObject')
            @srgb.set('selectedStudent', student)
    teardown: ->
      teardown.call this

  test 'selectedSubmission should be null when just selectedStudent is set', ->
    @completeSetup().then =>
      strictEqual @srgb.get('selectedSubmission'), null

  test 'assignments excludes any due for the selected student in a different grading period', ->
    @srgb.mgpEnabled = true
    @completeSetup().then =>
      deepEqual(@srgb.get('assignments').mapBy('id'), ['3'])

  module 'screenreader_gradebook_controller: with selected student, assignment, and outcome',
    setup: ->
      setup.call this
      @completeSetup = =>
        Ember.run =>
          workAroundRaceCondition().then =>
            @student = @srgb.get('students.firstObject')
            @assignment = @srgb.get('assignments.firstObject')
            @outcome = @srgb.get('outcomes.firstObject')
            @srgb.set('selectedStudent', @student)
            @srgb.set('selectedAssignment', @assignment)
            @srgb.set('selectedOutcome', @outcome)

    teardown: ->
      teardown.call this

  test 'assignmentDetails is computed properly', ->
    @completeSetup().then =>
      ad = @srgb.get('assignmentDetails')
      selectedAssignment = @srgb.get('selectedAssignment')
      strictEqual ad.assignment, selectedAssignment
      strictEqual ad.cnt, 1

  test 'outcomeDetails is computed properly', ->
    @completeSetup().then =>
      od = @srgb.get('outcomeDetails')
      selectedOutcome = @srgb.get('selectedOutcome')
      strictEqual od.cnt, 1

  test 'selectedSubmission is computed properly', ->
    @completeSetup().then =>
      selectedSubmission = @srgb.get('selectedSubmission')
      sub = _.find(fixtures.submissions, (s) => s.user_id == @student.id)
      submission = _.find(sub.submissions, (s) => s.assignment_id == @assignment.id)
      _.each submission, (val, key) =>
        equal selectedSubmission[key], val, "#{key} is the expected value on selectedSubmission"

  test 'selectedSubmission sets gradeLocked', ->
    @completeSetup().then =>
      selectedSubmission = @srgb.get('selectedSubmission')
      equal selectedSubmission.gradeLocked, false

  test 'selectedSubmission sets gradeLocked for unassigned students', ->
    @completeSetup().then =>
      @student = @srgb.get('students')[1]
      Ember.run =>
        @srgb.set('selectedStudent', @student)
        selectedSubmission = @srgb.get('selectedSubmission')
        equal selectedSubmission.gradeLocked, true

  module 'screenreader_gradebook_controller: with selected assignment',
    setup: ->
      setup.call this
      @completeSetup = =>
        workAroundRaceCondition().then =>
          @assignment = @srgb.get('assignments.firstObject')
          Ember.run =>
            @srgb.set('selectedAssignment', @assignment)

    teardown: ->
      @contextGetStub.restore()
      @contextSetStub.restore()
      Ember.run App, 'destroy'

  test 'gets the submission types', ->
    @completeSetup().then =>
      equal @srgb.get('assignmentSubmissionTypes'), 'None'
      Ember.run =>
        assignments = @srgb.get('assignments')
        @srgb.set('selectedAssignment', assignments.objectAt(1))
      equal @srgb.get('assignmentSubmissionTypes'), 'Online URL, Online text entry'

  test 'assignmentInClosedGradingPeriod returns false when the selected assignment does not have
    a due date in a closed grading period', ->
    @completeSetup().then =>
      Ember.run =>
        assignment = @srgb.get('assignments.lastObject')
        assignment.inClosedGradingPeriod = false
        @srgb.set('selectedAssignment', assignment)
      equal @srgb.get('assignmentInClosedGradingPeriod'), false

  test 'assignmentInClosedGradingPeriod returns true when the selected assignment has
    a due date in a closed grading period', ->
    @completeSetup().then =>
      Ember.run =>
        assignment = @srgb.get('assignments.lastObject')
        assignment.inClosedGradingPeriod = true
        @srgb.set('selectedAssignment', assignment)
      equal @srgb.get('assignmentInClosedGradingPeriod'), true

  module 'screenreader_gradebook_controller:draftState',
    setup: ->
      setup.call this, true
      @completeSetup = =>
        workAroundRaceCondition().then =>
          Ember.run =>
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
    @completeSetup().then =>
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
    workAroundRaceCondition().then =>
      equal @srgb.get('students.firstObject.total_percent'), 79.55

  module 'grade calc with 0s',
    setup: ->
      calculationSetup.call this, calc_stub_with_0_possible

  test 'calculates final grade', ->
    workAroundRaceCondition().then =>
      equal @srgb.get('students.firstObject.total_percent'), 0


  module 'screenreader_gradebook_controller: notes computed props',
    setup: ->
      setup.call this
      window.ENV.GRADEBOOK_OPTIONS.custom_column_url = '/here/is/an/:id'
      window.ENV.GRADEBOOK_OPTIONS.teacher_notes = id:'42'
      @server = sinon.fakeServer.create()
      Ember.run =>
        #@srgb.set('custom_columns', [{teacher_notes: true, id: '42'}])
        @srgb.reopen
          updateOrCreateNotesColumn: ->
    teardown: ->
      window.ENV.GRADEBOOK_OPTIONS.custom_column_url = null
      window.ENV.GRADEBOOK_OPTIONS.teacher_notes = null
      @server.restore()
      teardown.call this

  test 'computes showNotesColumn correctly', ->
    window.ENV.GRADEBOOK_OPTIONS.teacher_notes =
      hidden: false
    equal @srgb.get('showNotesColumn'), true

    window.ENV.GRADEBOOK_OPTIONS.teacher_notes =
      hidden: true
    equal @srgb.get('showNotesColumn'), false

    window.ENV.GRADEBOOK_OPTIONS.teacher_notes = null
    equal @srgb.get('showNotesColumn'), false

  test 'shouldCreateNotes, no notes in ENV', ->
    window.ENV.GRADEBOOK_OPTIONS.teacher_notes = null
    Ember.run =>
      @srgb.set('showNotesColumn', true)
    equal @srgb.get('shouldCreateNotes'), true, 'true if no teacher_notes and showNotesColumns is true'

  test 'shouldCreateNotes, notes in ENV, hidden', ->
    window.ENV.GRADEBOOK_OPTIONS.teacher_notes =
      hidden: true
    Ember.run =>
      @srgb.set('showNotesColumn', true)
    actual = @srgb.get('shouldCreateNotes')
    equal actual, false, 'does not create if there is a teacher_notes object in the ENV'

  test 'shouldCreateNotes, notes in ENV, shown', ->
    window.ENV.GRADEBOOK_OPTIONS.teacher_notes =
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
      Ember.run =>
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
    workAroundRaceCondition().then =>
      student = @srgb.get('students').objectAt(2)
      assignment = @srgb.get('assignments.firstObject')

      Ember.run =>
        @srgb.set('selectedAssignment', assignment)
        @srgb.set('selectedStudent', student)
        equal @srgb.get('selectedSubmissionHidden'), true

  module 'screenreader_gradebook_controller: selectedOutcomeResult',
    setup: -> setup.call @
    teardown: -> teardown.call @

  test 'should return object including mastery_points if result is found', ->
    student = @srgb.get('students.firstObject')
    outcome = @srgb.get('outcomes.firstObject')

    Ember.run =>
      @srgb.set('selectedOutcome', outcome)
      @srgb.set('selectedStudent', student)
      equal @srgb.get('selectedOutcomeResult').mastery_points, outcome.mastery_points
