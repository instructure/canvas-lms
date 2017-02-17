define [
  'compiled/models/AssignmentGroup'
  'compiled/models/Assignment'
  'compiled/collections/AssignmentGroupCollection'
  'compiled/models/Course'
  'helpers/fakeENV'
], (AssignmentGroup, Assignment, AssignmentGroupCollection, Course, fakeENV) ->

  COURSE_SUBMISSIONS_URL = "/courses/1/submissions"

  QUnit.module "AssignmentGroupCollection",
    setup: ->
      fakeENV.setup()
      @server       = sinon.fakeServer.create()
      @assignments  = (new Assignment({id: id}) for id in [1..4])
      @group        = new AssignmentGroup assignments: @assignments
      @collection   = new AssignmentGroupCollection [@group],
        courseSubmissionsURL: COURSE_SUBMISSIONS_URL

    teardown: ->
      fakeENV.teardown()
      @server.restore()

  test "::model is AssignmentGroup", ->
    strictEqual AssignmentGroupCollection::model, AssignmentGroup

  test "default params include assignments and not discussion topics", ->
    {include} = AssignmentGroupCollection::defaults.params
    deepEqual include, ["assignments"], "include only contains assignments"

  test "optionProperties", ->
    course     = new Course
    collection = new AssignmentGroupCollection [],
      course: course
      courseSubmissionsURL: COURSE_SUBMISSIONS_URL

    strictEqual collection.courseSubmissionsURL, COURSE_SUBMISSIONS_URL,
      "assigns courseSubmissionsURL to this.courseSubmissionsURL"

    strictEqual collection.course, course, "assigns course to this.course"

  test "(#getGrades) loading grades from the server", ->
    ENV.observed_student_ids = []
    ENV.PERMISSIONS.read_grades = true
    triggeredChangeForAssignmentWithoutSubmission = false
    submissions = ({id: id, assignment_id: id, grade: id} for id in [1..3])
    @server.respondWith "GET", "#{COURSE_SUBMISSIONS_URL}?per_page=50", [
      200,
      { "Content-Type": "application/json" },
      JSON.stringify(submissions)
    ]

    lastAssignment = @assignments[3]
    lastAssignment.on 'change:submission', ->
      triggeredChangeForAssignmentWithoutSubmission = true

    @collection.getGrades()
    @server.respond()

    for assignment in @assignments
      continue if assignment.get("id") is 4
      equal assignment.get("submission").get("grade"), assignment.get("id"),
        "sets submission grade for assignments with a matching submission"

    ok triggeredChangeForAssignmentWithoutSubmission,
      """
      triggers change for assignments without a matching submission grade
      so the UI can update
      """

