define ['compiled/gradebook2/PostGradesModel'], (PostGradesModel) ->

  module "Gradebook2",
    setup: ->
      @assignments = {
        1: {id: 1, name: "one", due_at: null, needs_grading_count: 0},
        2: {id: 2, name: "one", due_at: null, needs_grading_count: 1},
        3: {id: 3, name: "three", due_at: new Date(), needs_grading_count: 2}
      }
      @model = new PostGradesModel(assignments: @assignments,
        course_id: 1
        integration_course_id: 'xyz'
      )

  test "model not null", ->
    ok @model != null, "model should not be null"

  test "assignment_list", ->
    ok @model.assignment_list().length == 3, "size of assignment list should be 3"

  test "assignments can be ignored", ->
    @model.ignore_assignment(1)
    ok @model.assignments_to_post().length == 2, "size of assignments not ignored should be 2"

  test "all assignments can be ignored", ->
    @model.ignore_all()
    ok @model.assignments_to_post().length == 1, "all assignments except 'three' should be ignored"

  test "update_assignment", ->
    ok !@model.get('assignments')[1].modified, "assignment 1 should not be not modified"
    ok !@model.get('assignments')[2].modified, "assignment 2 should not be not modified"
    ok !@model.get('assignments')[3].modified, "assignment 3 should not be not modified"

    @model.update_assignment(1, {due_at: new Date()})

    ok @model.get('assignments')[1].modified, "assignment 1 should be not modified"
    ok !@model.get('assignments')[2].modified, "assignment 2 should not be not modified"
    ok !@model.get('assignments')[3].modified, "assignment 3 should not be not modified"

    ok @model.get('assignments')[1].due_at != null, "assignment 1 should have a due date"

  test "modified_assignments", ->
    ok @model.modified_assignments().length == 0, "should not be any modified assignments yet"

    @model.update_assignment(1, {due_at: new Date()})

    ok @model.modified_assignments().length == 1, "should have 1 modified assignment"

  test "assignments_with_errors_count", ->
    ok @model.assignments_with_errors_count() == 2, "should have 2 assignments with missing due_at"

  test "not_unique_assignments", ->
    ok @model.not_unique_assignments().length == 2, "should have 2 assignments with same name"

  test "missing_due_date", ->
    ok @model.missing_due_date().length == 2, "should have 2 assignments missing due date"

  test "missing_and_not_unique", ->
    mnu = @model.missing_and_not_unique().length
    ok mnu == 2, "total assignments w/ errors should be 2 (not #{mnu})"

  test "ungraded_submissions", ->
    ok @model.ungraded_submissions().length == 2, "ungraded submissions should be 2"

