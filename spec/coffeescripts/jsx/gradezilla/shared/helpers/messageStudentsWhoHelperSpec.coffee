#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'underscore'
  'jsx/gradezilla/shared/helpers/messageStudentsWhoHelper'
], (_, MessageStudentsWhoHelper) ->

  QUnit.module "messageStudentsWhoHelper#options",
    setup: ->
      @assignment = { id: '1', name: 'Shootbags'}

  test "Includes the 'Haven't been graded' option if there are submissions", ->
    @stub(MessageStudentsWhoHelper, 'hasSubmission').returns(true)
    options = MessageStudentsWhoHelper.options(@assignment)
    deepEqual options[1].text, "Haven't been graded"

  test "Does not include the 'Haven't been graded' option if there are no submissions", ->
    @stub(MessageStudentsWhoHelper, 'hasSubmission').returns(false)
    options = MessageStudentsWhoHelper.options(@assignment)
    deepEqual options[1].text, "Scored less than"

  QUnit.module "messageStudentsWhoHelper#hasSubmission"

  test "returns false if there are no submission types", ->
    assignment = { id: '1', name: 'Shootbags', submission_types: [] }
    hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
    deepEqual hasSubmission, false

  test "returns false if there are no submission types and submissionTypes is camelCase", ->
    assignment = { id: '1', name: 'Shootbags', submissionTypes: [] }
    hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
    deepEqual hasSubmission, false

  test "returns false if the only submission type is 'none'", ->
    assignment = { id: '1', name: 'Shootbags', submission_types: ['none'] }
    hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
    deepEqual hasSubmission, false

  test "returns false if the only submission type is 'none' and submissionTypes is camelCase", ->
    assignment = { id: '1', name: 'Shootbags', submissionTypes: ['none'] }
    hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
    deepEqual hasSubmission, false

  test "returns false if the only submission type is 'on_paper'", ->
    assignment = { id: '1', name: 'Shootbags', submission_types: ['on_paper'] }
    hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
    deepEqual hasSubmission, false

  test "returns false if the only submission type is 'on_paper' and submissionTypes is camelCase", ->
    assignment = { id: '1', name: 'Shootbags', submissionTypes: ['on_paper'] }
    hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
    deepEqual hasSubmission, false

  test "returns false if the only submission types are 'none' and 'on_paper'", ->
    assignment = { id: '1', name: 'Shootbags', submission_types: ['none', 'on_paper'] }
    hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
    deepEqual hasSubmission, false

  test "returns false if the only submission types are 'none' and 'on_paper' and submissionTypes is camelCase", ->
    assignment = { id: '1', name: 'Shootbags', submissionTypes: ['none', 'on_paper'] }
    hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
    deepEqual hasSubmission, false

  test "returns true if there is at least one submission that is not of type 'non' or 'on_paper'", ->
    assignment = { id: '1', name: 'Shootbags', submission_types: ['online_quiz'] }
    hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
    deepEqual hasSubmission, true

  test "returns true if there is at least one submission that is not of type 'non' or 'on_paper' and submissionTypes is camelCase", ->
    assignment = { id: '1', name: 'Shootbags', submissionTypes: ['online_quiz'] }
    hasSubmission = MessageStudentsWhoHelper.hasSubmission(assignment)
    deepEqual hasSubmission, true

  QUnit.module "messageStudentsWhoHelper#scoreWithCutoff"

  test "returns true if the student has a non-empty-string score and a cutoff", ->
    student = { score: 6 }
    cutoff = 5
    scoreWithCutoff = MessageStudentsWhoHelper.scoreWithCutoff(student, cutoff)
    deepEqual scoreWithCutoff, true

  test "returns false if the student has an empty-string score", ->
    student = { score: '' }
    cutoff = 5
    scoreWithCutoff = MessageStudentsWhoHelper.scoreWithCutoff(student, cutoff)
    deepEqual scoreWithCutoff, false

  test "returns false if the student score is null or undefined", ->
    student = {}
    cutoff = 5
    scoreWithCutoff = MessageStudentsWhoHelper.scoreWithCutoff(student, cutoff)
    deepEqual scoreWithCutoff, false
    student.score = null
    scoreWithCutoff = MessageStudentsWhoHelper.scoreWithCutoff(student, cutoff)
    deepEqual scoreWithCutoff, false

  test "returns false if the cutoff is null or undefined", ->
    student = { score: 5 }
    scoreWithCutoff = MessageStudentsWhoHelper.scoreWithCutoff(student, cutoff)
    deepEqual scoreWithCutoff, false
    cutoff = null
    scoreWithCutoff = MessageStudentsWhoHelper.scoreWithCutoff(student, cutoff)
    deepEqual scoreWithCutoff, false

  QUnit.module 'messageStudentsWhoHelper#callbackFn'

  test "returns the student ids filtered by the correct criteria", ->
    option = { criteriaFn: (student, cutoff) -> student.score > cutoff }
    @stub(MessageStudentsWhoHelper, 'findOptionByText').returns(option)
    students = [{ user_data: { id: '1', score: 8 } }, { user_data: { id: '2', score: 4 } }]
    cutoff = 5
    selected = "Scored more than"
    filteredStudents = MessageStudentsWhoHelper.callbackFn(selected, cutoff, students)
    deepEqual filteredStudents.length, 1
    deepEqual filteredStudents[0], '1'


  QUnit.module 'messageStudentsWhoHelper#generateSubjectCallbackFn'

  test "generates a function that returns the subject string", ->
    option = { subjectFn: (assignment, cutoff) -> 'name: ' + assignment.name + ', cutoff: ' + cutoff }
    @stub(MessageStudentsWhoHelper, 'findOptionByText').returns(option)
    assignment = { id: '1', name: 'Shootbags' }
    cutoff = 5
    subjectCallbackFn = MessageStudentsWhoHelper.generateSubjectCallbackFn(assignment)
    deepEqual subjectCallbackFn(assignment,cutoff), 'name: Shootbags, cutoff: 5'

  QUnit.module 'messageStudentsWhoHelper#settings'

  test "returns an object with the expected settings", ->
    assignment =
      id: '1'
      name: 'Shootbags'
      points_possible: 5
      course_id: '5'
    students = [{ id: '1', name: 'Dora' }]
    self =
      options: -> 'stuff'
      callbackFn: -> 'call me back!'
      generateSubjectCallbackFn: -> -> 'function inception'
    settingsFn = MessageStudentsWhoHelper.settings.bind(self)
    settings = settingsFn(assignment, students)

    settingsKeys = _.keys settings
    expectedKeys = ["options", "title", "points_possible",
      "students", "context_code", "callback", "subjectCallback"]

    deepEqual settingsKeys, expectedKeys

  test "returns an object with the expected settings and courseId is camelCase", ->
    assignment =
      id: '1'
      name: 'Shootbags'
      points_possible: 5
      courseId: '5'
    students = [{ id: '1', name: 'Dora' }]
    self =
      options: -> 'stuff'
      callbackFn: -> 'call me back!'
      generateSubjectCallbackFn: -> -> 'function inception'
    settingsFn = MessageStudentsWhoHelper.settings.bind(self)
    settings = settingsFn(assignment, students)

    settingsKeys = _.keys settings
    expectedKeys = ["options", "title", "points_possible",
      "students", "context_code", "callback", "subjectCallback"]

    deepEqual settingsKeys, expectedKeys

  QUnit.module 'messageStudentsWhoHelper#options'

  test "returns a `Haven't submitted yet option` with a criteriaFn that checks submission date", ->
    assignment = { id: '1', name: 'Shootbags', submission_types: 'arbitrary' }
    studentWithSubmission = { submitted_at: new Date() }
    studentWithoutSubmission = {}
    options = MessageStudentsWhoHelper.options(assignment)

    notOk(options[0].criteriaFn(studentWithSubmission))
    ok(options[0].criteriaFn(studentWithoutSubmission))

  test "returns a `Haven't submitted yet option` with a criteriaFn that checks submission date and submittedAt is camelCase", ->
    assignment = { id: '1', name: 'Shootbags', submission_types: 'arbitrary' }
    studentWithSubmission = { submittedAt: new Date() }
    options = MessageStudentsWhoHelper.options(assignment)

    notOk(options[0].criteriaFn(studentWithSubmission))

