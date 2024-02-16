/*
 * Copyright (C) 2013 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import 'jquery-migrate'
import '@canvas/jquery/jquery.ajaxJSON'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import Submission from '@canvas/assignments/backbone/models/Submission'
import DateGroup from '@canvas/date-group/backbone/models/DateGroup'
import fakeENV from 'helpers/fakeENV'

QUnit.module('Assignment#initialize with ENV.POST_TO_SIS set to false', {
  setup() {
    fakeENV.setup({POST_TO_SIS: false})
  },
  teardown() {
    fakeENV.teardown()
  },
})

test('must not alter the post_to_sis field', () => {
  const assignment = new Assignment()
  strictEqual(assignment.get('post_to_sis'), undefined)
})

QUnit.module('Assignment#initalize with ENV.POST_TO_SIS set to true', {
  setup() {
    fakeENV.setup({
      POST_TO_SIS: true,
      POST_TO_SIS_DEFAULT: true,
    })
  },
  teardown() {
    fakeENV.teardown()
  },
})

test('must default post_to_sis to true for a new assignment', () => {
  const assignment = new Assignment()
  strictEqual(assignment.get('post_to_sis'), true)
})

test('must leave a false value as is', () => {
  const assignment = new Assignment({post_to_sis: false})
  strictEqual(assignment.get('post_to_sis'), false)
})

test('must leave a null value as is for an existing assignment', () => {
  const assignment = new Assignment({
    id: '1234',
    post_to_sis: null,
  })
  strictEqual(assignment.get('post_to_sis'), null)
})

QUnit.module('Assignment#isQuiz')

test('returns true if record is a quiz', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('submission_types', ['online_quiz'])
  equal(assignment.isQuiz(), true)
})

test('returns false if record is not a quiz', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('submission_types', ['on_paper'])
  equal(assignment.isQuiz(), false)
})

QUnit.module('Assignment#isDiscussionTopic')

test('returns true if record is discussion topic', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.submissionTypes(['discussion_topic'])
  equal(assignment.isDiscussionTopic(), true)
})

test('returns false if record is discussion topic', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.submissionTypes(['on_paper'])
  equal(assignment.isDiscussionTopic(), false)
})

QUnit.module('default submission types', {
  setup() {
    fakeENV.setup({
      DEFAULT_ASSIGNMENT_TOOL_NAME: 'Default Tool',
      DEFAULT_ASSIGNMENT_TOOL_URL: 'https://www.test.com/blti',
    })
  },
  teardown() {
    fakeENV.teardown()
  },
})

test('defaultToNone returns true if submission type is "none"', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.submissionTypes(['none'])
  equal(assignment.defaultToNone(), true)
})

test('defaultToNone returns false if default tool configured and new assignment', () => {
  const assignment = new Assignment()
  equal(assignment.defaultToNone(), false)
})

test('defaultToOnline returns true if submission type is "online"', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.submissionTypes(['online'])
  equal(assignment.defaultToOnline(), true)
})

test('defaultToOnline returns false if default tool configured and new assignment', () => {
  const assignment = new Assignment()
  equal(assignment.defaultToOnline(), false)
})

test('defaultToOnPaper returns true if submission type is "on_paper"', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.submissionTypes(['on_paper'])
  equal(assignment.defaultToOnPaper(), true)
})

test('defaultToOnPaper returns false if default tool configured and new assignment', () => {
  const assignment = new Assignment()
  equal(assignment.defaultToOnPaper(), false)
})

QUnit.module('Assignment#isDefaultTool', {
  setup() {
    fakeENV.setup({
      DEFAULT_ASSIGNMENT_TOOL_NAME: 'Default Tool',
      DEFAULT_ASSIGNMENT_TOOL_URL: 'https://www.test.com/blti',
    })
  },
  teardown() {
    fakeENV.teardown()
  },
})

test('returns true if submissionType is "external_tool" and default tool is selected', () => {
  const assignment = new Assignment({
    name: 'foo',
    external_tool_tag_attributes: {
      url: 'https://www.test.com/blti?foo',
    },
  })
  assignment.submissionTypes(['external_tool'])
  equal(assignment.isDefaultTool(), true)
})

QUnit.module('Assignment#isGenericExternalTool', {
  setup() {
    fakeENV.setup({
      DEFAULT_ASSIGNMENT_TOOL_NAME: 'Default Tool',
      DEFAULT_ASSIGNMENT_TOOL_URL: 'https://www.test.com/blti',
    })
  },
  teardown() {
    fakeENV.teardown()
  },
})

test('returns true if submissionType is "default_external_tool"', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.submissionTypes(['default_external_tool'])
  equal(assignment.isDefaultTool(), true)
})

test('returns true when submissionType is "external_tool" and non default tool is selected', () => {
  const assignment = new Assignment({
    name: 'foo',
    external_tool_tag_attributes: {
      url: 'https://www.non-default.com/blti?foo',
    },
  })
  assignment.submissionTypes(['external_tool'])
  equal(assignment.isGenericExternalTool(), true)
})

test('returns true when submissionType is "external_tool"', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.submissionTypes(['external_tool'])
  equal(assignment.isGenericExternalTool(), true)
})

QUnit.module('Assignment#isExternalTool')

test('returns true if record is external tool', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.submissionTypes(['external_tool'])
  equal(assignment.isExternalTool(), true)
})

QUnit.module('Assignment#defaultToolName', {
  setup() {
    fakeENV.setup({
      DEFAULT_ASSIGNMENT_TOOL_NAME: 'Default Tool <a href="https://www.somethingbad.com">',
    })
  },
  teardown() {
    fakeENV.teardown()
  },
})

test('escapes the name retrieved from the js env', () => {
  const assignment = new Assignment({name: 'foo'})
  equal(
    assignment.defaultToolName(),
    'Default Tool %3Ca href%3D%22https%3A//www.somethingbad.com%22%3E'
  )
})

QUnit.module('Assignment#defaultToolName is undefined', {
  setup() {
    fakeENV.setup({
      DEFAULT_ASSIGNMENT_TOOL_NAME: undefined,
    })
  },
  teardown() {
    fakeENV.teardown()
  },
})

test('does not convert undefined to string', () => {
  const assignment = new Assignment({name: 'foo'})
  equal(assignment.defaultToolName(), undefined)
})

test('returns false if record is not external tool', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.submissionTypes(['on_paper'])
  equal(assignment.isExternalTool(), false)
})

QUnit.module('Assignment#isNotGraded')

test('returns true if record is not graded', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.submissionTypes(['not_graded'])
  equal(assignment.isNotGraded(), true)
})

test('returns false if record is graded', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.gradingType('percent')
  assignment.submissionTypes(['online_url'])
  equal(assignment.isNotGraded(), false)
})

QUnit.module('Assignment#asignmentType as a setter')

test("sets the record's submission_types to the value", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('submission_types', 'online_quiz')
  assignment.assignmentType('discussion_topic')
  equal(assignment.assignmentType(), 'discussion_topic')
  deepEqual(assignment.get('submission_types'), ['discussion_topic'])
})

test("when value 'assignment', sets record value to 'none'", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('submission_types', 'online_quiz')
  assignment.assignmentType('assignment')
  equal(assignment.assignmentType(), 'assignment')
  deepEqual(assignment.get('submission_types'), ['none'])
})

QUnit.module('Assignment#moderatedGrading', () => {
  test('returns false if the moderated_grading attribute is undefined', () => {
    const assignment = new Assignment()
    strictEqual(assignment.moderatedGrading(), false)
  })

  test('returns false if the moderated_grading attribute is set to false', () => {
    const assignment = new Assignment({moderated_grading: false})
    strictEqual(assignment.moderatedGrading(), false)
  })

  test('returns true if the moderated_grading attribute is set to true', () => {
    const assignment = new Assignment({moderated_grading: true})
    strictEqual(assignment.moderatedGrading(), true)
  })
})

QUnit.module('Assignment#assignmentType as a getter')

test("returns 'assignment' if not quiz, discussion topic, external tool, or ungraded", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('submission_types', ['on_paper'])
  equal(assignment.assignmentType(), 'assignment')
})

test("returns correct assignment type if not 'assignment'", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('submission_types', ['online_quiz'])
  equal(assignment.assignmentType(), 'online_quiz')
})

QUnit.module('Assignment#dueAt as a getter')

test("returns record's due_at", () => {
  const date = Date.now()
  const assignment = new Assignment({name: 'foo'})
  assignment.set('due_at', date)
  equal(assignment.dueAt(), date)
})

QUnit.module('Assignment#dueAt as a setter')

test("sets the record's due_at", () => {
  const date = Date.now()
  const assignment = new Assignment({name: 'foo'})
  assignment.set('due_at', null)
  assignment.dueAt(date)
  equal(assignment.dueAt(), date)
})

QUnit.module('Assignment#unlockAt as a getter')

test('gets the records unlock_at', () => {
  const date = Date.now()
  const assignment = new Assignment({name: 'foo'})
  assignment.set('unlock_at', date)
  equal(assignment.unlockAt(), date)
})

QUnit.module('Assignment#unlockAt as a setter')

test("sets the record's unlock_at", () => {
  const date = Date.now()
  const assignment = new Assignment({name: 'foo'})
  assignment.set('unlock_at', null)
  assignment.unlockAt(date)
  equal(assignment.unlockAt(), date)
})

QUnit.module('Assignment#lockAt as a getter')

test('gets the records lock_at', () => {
  const date = Date.now()
  const assignment = new Assignment({name: 'foo'})
  assignment.set('lock_at', date)
  equal(assignment.lockAt(), date)
})

QUnit.module('Assignment#lockAt as a setter')

test("sets the record's lock_at", () => {
  const date = Date.now()
  const assignment = new Assignment({name: 'foo'})
  assignment.set('unlock_at', null)
  assignment.lockAt(date)
  equal(assignment.lockAt(), date)
})

QUnit.module('Assignment#description as a getter')

test("returns the record's description", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('description', 'desc')
  equal(assignment.description(), 'desc')
})

QUnit.module('Assignment#description as a setter')

test("sets the record's description", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('description', null)
  assignment.description('desc')
  equal(assignment.description(), 'desc')
  equal(assignment.get('description'), 'desc')
})

QUnit.module('Assignment#dueDateRequired as a getter')

test("returns the record's dueDateRequired", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('dueDateRequired', true)
  equal(assignment.dueDateRequired(), true)
})

QUnit.module('Assignment#dueDateRequired as a setter')

test("sets the record's dueDateRequired", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('dueDateRequired', null)
  assignment.dueDateRequired(true)
  equal(assignment.dueDateRequired(), true)
  equal(assignment.get('dueDateRequired'), true)
})

QUnit.module('Assignment#name as a getter')

test("returns the record's name", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('name', 'Todd')
  equal(assignment.name(), 'Todd')
})

QUnit.module('Assignment#name as a setter')

test("sets the record's name", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('name', 'NotTodd')
  assignment.name('Todd')
  equal(assignment.get('name'), 'Todd')
})

QUnit.module('Assignment#pointsPossible as a setter')

test("sets the record's points_possible", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('points_possible', 0)
  assignment.pointsPossible(12)
  equal(assignment.pointsPossible(), 12)
  equal(assignment.get('points_possible'), 12)
})

QUnit.module('Assignment#secureParams as a getter')

test('returns secure params if set', () => {
  const secure_params = 'eyJ0eXAiOiJKV1QiLCJhb.asdf232.asdf2334'
  const assignment = new Assignment({name: 'foo'})
  assignment.set('secure_params', secure_params)
  equal(assignment.secureParams(), secure_params)
})

QUnit.module('Assignment#assignmentGroupId as a setter')

test("sets the record's assignment group id", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('assignment_group_id', 0)
  assignment.assignmentGroupId(12)
  equal(assignment.assignmentGroupId(), 12)
  equal(assignment.get('assignment_group_id'), 12)
})

QUnit.module('Assignment#canDelete', {
  setup() {
    fakeENV.setup({current_user_roles: ['teacher'], current_user_is_admin: false})
  },
  teardown() {
    fakeENV.teardown()
  },
})

test("returns false if 'frozen' is true", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('frozen', true)
  equal(assignment.canDelete(), false)
})

test("returns false if 'in_closed_grading_period' is true", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('in_closed_grading_period', true)
  equal(assignment.canDelete(), false)
})

test("returns true if 'frozen' and 'in_closed_grading_period' are false", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('frozen', false)
  assignment.set('in_closed_grading_period', false)
  equal(assignment.canDelete(), true)
})

QUnit.module('Assignment#canMove as teacher', {
  setup() {
    fakeENV.setup({current_user_roles: ['teacher'], current_user_is_admin: false})
  },
  teardown() {
    fakeENV.teardown()
  },
})

test('returns false if grading period is closed', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('in_closed_grading_period', true)
  equal(assignment.canMove(), false)
})

test('returns false if grading period not closed but group id is locked', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('in_closed_grading_period', false)
  assignment.set('in_closed_grading_period', ['assignment_group_id'])
  equal(assignment.canMove(), false)
})

test('returns true if grading period not closed and and group id is not locked', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('in_closed_grading_period', false)
  equal(assignment.canMove(), true)
})

QUnit.module('Assignment#canMove as admin', {
  setup() {
    fakeENV.setup({current_user_is_admin: true})
  },
  teardown() {
    fakeENV.teardown()
  },
})

test('returns true if grading period is closed', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('in_closed_grading_period', true)
  equal(assignment.canMove(), true)
})

test('returns true if grading period not closed but group id is locked', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('in_closed_grading_period', false)
  assignment.set('in_closed_grading_period', ['assignment_group_id'])
  equal(assignment.canMove(), true)
})

test('returns true if grading period not closed and and group id is not locked', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('in_closed_grading_period', false)
  equal(assignment.canMove(), true)
})

QUnit.module('Assignment#inClosedGradingPeriod as a non admin', {
  setup() {
    fakeENV.setup({current_user_roles: ['teacher'], current_user_is_admin: false})
  },
  teardown() {
    fakeENV.teardown()
  },
})

test("returns the value of 'in_closed_grading_period' when isAdmin is false", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('in_closed_grading_period', true)
  equal(assignment.inClosedGradingPeriod(), true)
  assignment.set('in_closed_grading_period', false)
  equal(assignment.inClosedGradingPeriod(), false)
})

QUnit.module('Assignment#inClosedGradingPeriod as an admin', {
  setup() {
    fakeENV.setup({current_user_is_admin: true})
  },
  teardown() {
    fakeENV.teardown()
  },
})

test('returns true when isAdmin is true', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('in_closed_grading_period', true)
  equal(assignment.inClosedGradingPeriod(), false)
  assignment.set('in_closed_grading_period', false)
  equal(assignment.inClosedGradingPeriod(), false)
})

QUnit.module('Assignment#gradingType as a setter')

test("sets the record's grading type", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('grading_type', 'points')
  assignment.gradingType('percent')
  equal(assignment.gradingType(), 'percent')
  equal(assignment.get('grading_type'), 'percent')
})

QUnit.module('Assignment#submissionType')

test("returns 'none' if record's submission_types is ['none']", () => {
  const assignment = new Assignment({
    name: 'foo',
    id: '12',
  })
  assignment.set('submission_types', ['none'])
  equal(assignment.submissionType(), 'none')
})

test("returns 'on_paper' if record's submission_types includes on_paper", () => {
  const assignment = new Assignment({
    name: 'foo',
    id: '13',
  })
  assignment.set('submission_types', ['on_paper'])
  equal(assignment.submissionType(), 'on_paper')
})

test('returns online submission otherwise', () => {
  const assignment = new Assignment({
    name: 'foo',
    id: '14',
  })
  assignment.set('submission_types', ['online_upload'])
  equal(assignment.submissionType(), 'online')
})

QUnit.module('Assignment#expectsSubmission')

test('returns false if assignment submission type is not online', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set({
    submission_types: ['external_tool', 'on_paper'],
  })
  equal(assignment.expectsSubmission(), false)
})

test('returns true if an assignment submission type is online', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set({submission_types: ['online']})
  equal(assignment.expectsSubmission(), true)
})

QUnit.module('Assignment#allowedToSubmit')

test('returns false if assignment is locked', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set({submission_types: ['online']})
  assignment.set({locked_for_user: true})
  equal(assignment.allowedToSubmit(), false)
})

test('returns true if an assignment is not locked', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set({submission_types: ['online']})
  assignment.set({locked_for_user: false})
  equal(assignment.allowedToSubmit(), true)
})

test('returns false if a submission is not expected', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set({
    submission_types: ['external_tool', 'on_paper', 'attendance'],
  })
  equal(assignment.allowedToSubmit(), false)
})

QUnit.module('Assignment#withoutGradedSubmission')

test('returns false if there is a submission', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set({submission: new Submission({submission_type: 'online'})})
  equal(assignment.withoutGradedSubmission(), false)
})

test('returns true if there is no submission', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set({submission: null})
  equal(assignment.withoutGradedSubmission(), true)
})

test('returns true if there is a submission, but no grade', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set({submission: new Submission()})
  equal(assignment.withoutGradedSubmission(), true)
})

test('returns false if there is a submission and a grade', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set({submission: new Submission({grade: 305})})
  equal(assignment.withoutGradedSubmission(), false)
})

QUnit.module('Assignment#acceptsOnlineUpload')

test('returns true if record submission types includes online_upload', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('submission_types', ['online_upload'])
  equal(assignment.acceptsOnlineUpload(), true)
})

test("returns false if submission types doesn't include online_upload", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('submission_types', [])
  equal(assignment.acceptsOnlineUpload(), false)
})

QUnit.module('Assignment#acceptsOnlineURL')

test('returns true if assignment allows online url', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('submission_types', ['online_url'])
  equal(assignment.acceptsOnlineURL(), true)
})

test("returns false if submission types doesn't include online_url", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('submission_types', [])
  equal(assignment.acceptsOnlineURL(), false)
})

QUnit.module('Assignment#acceptsMediaRecording')

test('returns true if submission types includes media recordings', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('submission_types', ['media_recording'])
  equal(assignment.acceptsMediaRecording(), true)
})

QUnit.module('Assignment#acceptsOnlineTextEntries')

test('returns true if submission types includes online text entry', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('submission_types', ['online_text_entry'])
  equal(assignment.acceptsOnlineTextEntries(), true)
})

QUnit.module('Assignment#peerReviews')

test('returns the peer_reviews on the record if no args passed', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('peer_reviews', false)
  equal(assignment.peerReviews(), false)
})

test("sets the record's peer_reviews if args passed", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('peer_reviews', false)
  assignment.peerReviews(true)
  equal(assignment.peerReviews(), true)
})

QUnit.module('Assignment#automaticPeerReviews')

test('returns the automatic_peer_reviews on the model if no args passed', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('automatic_peer_reviews', false)
  equal(assignment.automaticPeerReviews(), false)
})

test('sets the automatic_peer_reviews on the record if args passed', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('automatic_peer_reviews', false)
  assignment.automaticPeerReviews(true)
  equal(assignment.automaticPeerReviews(), true)
})

QUnit.module('Assignment#notifyOfUpdate')

test("returns record's notifyOfUpdate if no args passed", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('notify_of_update', false)
  equal(assignment.notifyOfUpdate(), false)
})

test("sets record's notifyOfUpdate if args passed", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.notifyOfUpdate(false)
  equal(assignment.notifyOfUpdate(), false)
})

QUnit.module('Assignment#multipleDueDates')

test('checks for multiple due dates from assignment overrides', () => {
  const assignment = new Assignment({
    all_dates: [{title: 'Winter'}, {title: 'Summer'}],
  })
  ok(assignment.multipleDueDates())
})

test('checks for no multiple due dates from assignment overrides', () => {
  const assignment = new Assignment()
  ok(!assignment.multipleDueDates())
})

QUnit.module('Assignment#allDates')

test('gets the due dates from the assignment overrides', () => {
  const dueAt = new Date('2013-08-20T11:13:00')
  const dates = [
    new DateGroup({
      due_at: dueAt,
      title: 'Everyone',
    }),
  ]
  const assignment = new Assignment({all_dates: dates})
  const allDates = assignment.allDates()
  const first = allDates[0]
  equal(`${first.dueAt}`, `${dueAt}`)
  equal(first.dueFor, 'Everyone')
})

test('gets empty due dates when there are no dates', () => {
  const assignment = new Assignment()
  deepEqual(assignment.allDates(), [])
})

QUnit.module('Assignment#inGradingPeriod', {
  setup() {
    this.gradingPeriod = {
      id: '1',
      title: 'Fall',
      startDate: new Date('2013-07-01T11:13:00'),
      endDate: new Date('2013-10-01T11:13:00'),
      closeDate: new Date('2013-10-05T11:13:00'),
      isLast: true,
      isClosed: true,
    }
    this.dateInPeriod = new Date('2013-08-20T11:13:00')
    this.dateOutsidePeriod = new Date('2013-01-20T11:13:00')
  },
})

test('returns true if the assignment has a due_at in the given period', function () {
  const assignment = new Assignment()
  assignment.set('due_at', this.dateInPeriod)
  equal(assignment.inGradingPeriod(this.gradingPeriod), true)
})

test('returns false if the assignment has a due_at outside the given period', function () {
  const assignment = new Assignment()
  assignment.set('due_at', this.dateOutsidePeriod)
  equal(assignment.inGradingPeriod(this.gradingPeriod), false)
})

test('returns true if the assignment has a date group in the given period', function () {
  const dates = [
    new DateGroup({
      due_at: this.dateInPeriod,
      title: 'Everyone',
    }),
  ]
  const assignment = new Assignment({all_dates: dates})
  equal(assignment.inGradingPeriod(this.gradingPeriod), true)
})

test('returns false if the assignment does not have a date group in the given period', function () {
  const dates = [
    new DateGroup({
      due_at: this.dateOutsidePeriod,
      title: 'Everyone',
    }),
  ]
  const assignment = new Assignment({all_dates: dates})
  equal(assignment.inGradingPeriod(this.gradingPeriod), false)
})

QUnit.module('Assignment#singleSectionDueDate', {
  setup() {
    fakeENV.setup()
  },
  teardown() {
    fakeENV.teardown()
  },
})

test('gets the due date for section instead of null', () => {
  const dueAt = new Date('2013-11-27T11:01:00Z')
  const assignment = new Assignment({
    all_dates: [
      {
        due_at: null,
        title: 'Everyone',
      },
      {
        due_at: dueAt,
        title: 'Summer',
      },
    ],
  })
  sandbox.stub(assignment, 'multipleDueDates').returns(false)
  equal(assignment.singleSectionDueDate(), dueAt.toISOString())
})

test('returns due_at when only one date/section are present', () => {
  const date = Date.now()
  const assignment = new Assignment({name: 'Taco party!'})
  assignment.set('due_at', date)
  equal(assignment.singleSectionDueDate(), assignment.dueAt())
  ENV.PERMISSIONS = {manage: false}
  equal(assignment.singleSectionDueDate(), assignment.dueAt())
  ENV.PERMISSIONS = {}
})

QUnit.module('Assignment#omitFromFinalGrade')

test("gets the record's omit_from_final_grade boolean", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('omit_from_final_grade', true)
  ok(assignment.omitFromFinalGrade())
})

test("sets the record's omit_from_final_grade boolean if args passed", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.omitFromFinalGrade(true)
  ok(assignment.omitFromFinalGrade())
})

QUnit.module('Assignment#hideInGradeBook')

test("gets the record's hide_in_gradebook boolean", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('hide_in_gradebook', true)
  ok(assignment.hideInGradebook())
})

test("sets the record's hide_in_gradebook boolean if args passed", () => {
  const assignment = new Assignment({name: 'bar'})
  assignment.hideInGradebook(true)
  ok(assignment.hideInGradebook())
})

QUnit.module('Assignment#toView', {
  setup() {
    fakeENV.setup({current_user_roles: ['teacher']})
  },
  teardown() {
    fakeENV.teardown()
  },
})

test("returns the assignment's name", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.name('Todd')
  const json = assignment.toView()
  equal(json.name, 'Todd')
})

test("returns the assignment's dueAt", () => {
  const date = Date.now()
  const assignment = new Assignment({name: 'foo'})
  assignment.dueAt(date)
  const json = assignment.toView()
  equal(json.dueAt, date)
})

test("includes the assignment's description", () => {
  const description = 'Yo yo fasho'
  const assignment = new Assignment({name: 'foo'})
  assignment.description(description)
  const json = assignment.toView()
  equal(json.description, description)
})

test("includes the assignment's dueDateRequired", () => {
  const dueDateRequired = false
  const assignment = new Assignment({name: 'foo'})
  assignment.dueDateRequired(dueDateRequired)
  const json = assignment.toView()
  equal(json.dueDateRequired, dueDateRequired)
})

test("returns assignment's points possible", () => {
  const pointsPossible = 12
  const assignment = new Assignment({name: 'foo'})
  assignment.pointsPossible(pointsPossible)
  const json = assignment.toView()
  equal(json.pointsPossible, pointsPossible)
})

test("returns assignment's lockAt", () => {
  const lockAt = Date.now()
  const assignment = new Assignment({name: 'foo'})
  assignment.lockAt(lockAt)
  const json = assignment.toView()
  equal(json.lockAt, lockAt)
})

test("includes assignment's unlockAt", () => {
  const unlockAt = Date.now()
  const assignment = new Assignment({name: 'foo'})
  assignment.unlockAt(unlockAt)
  const json = assignment.toView()
  equal(json.unlockAt, unlockAt)
})

test("includes assignment's gradingType", () => {
  const gradingType = 'percent'
  const assignment = new Assignment({name: 'foo'})
  assignment.gradingType(gradingType)
  const json = assignment.toView()
  equal(json.gradingType, gradingType)
})

test("includes assignment's notifyOfUpdate", () => {
  const notifyOfUpdate = false
  const assignment = new Assignment({name: 'foo'})
  assignment.notifyOfUpdate(notifyOfUpdate)
  const json = assignment.toView()
  equal(json.notifyOfUpdate, notifyOfUpdate)
})

test("includes assignment's peerReviews", () => {
  const peerReviews = false
  const assignment = new Assignment({name: 'foo'})
  assignment.peerReviews(peerReviews)
  const json = assignment.toView()
  equal(json.peerReviews, peerReviews)
})

test("includes assignment's automaticPeerReviews value", () => {
  const autoPeerReviews = false
  const assignment = new Assignment({name: 'foo'})
  assignment.automaticPeerReviews(autoPeerReviews)
  const json = assignment.toView()
  equal(json.automaticPeerReviews, autoPeerReviews)
})

test('includes boolean indicating whether or not assignment accepts uploads', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('submission_types', ['online_upload'])
  const json = assignment.toView()
  equal(json.acceptsOnlineUpload, true)
})

test('includes whether or not assignment accepts media recordings', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('submission_types', ['media_recording'])
  const json = assignment.toView()
  equal(json.acceptsMediaRecording, true)
})

test('includes submissionType', () => {
  const assignment = new Assignment({
    name: 'foo',
    id: '16',
  })
  assignment.set('submission_types', ['on_paper'])
  const json = assignment.toView()
  equal(json.submissionType, 'on_paper')
})

test('includes acceptsOnlineTextEntries', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('submission_types', ['online_text_entry'])
  const json = assignment.toView()
  equal(json.acceptsOnlineTextEntries, true)
})

test('includes acceptsOnlineURL', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('submission_types', ['online_url'])
  const json = assignment.toView()
  equal(json.acceptsOnlineURL, true)
})

test('includes allowedExtensions', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.allowedExtensions([])
  const json = assignment.toView()
  deepEqual(json.allowedExtensions, [])
})

test('includes htmlUrl', () => {
  const assignment = new Assignment({html_url: 'http://example.com/assignments/1'})
  const json = assignment.toView()
  equal(json.htmlUrl, 'http://example.com/assignments/1')
})

test('uses edit url for htmlUrl when managing a quiz_lti assignment', () => {
  const assignment = new Assignment({
    html_url: 'http://example.com/assignments/1',
    is_quiz_lti_assignment: true,
  })
  ENV.PERMISSIONS = {manage: true}
  const json = assignment.toView()
  equal(json.htmlUrl, 'http://example.com/assignments/1/edit?quiz_lti')
  ENV.PERMISSIONS = {}
  ENV.FLAGS = {}
})

test('uses htmlUrl when not managing a quiz_lti assignment', () => {
  const assignment = new Assignment({
    html_url: 'http://example.com/assignments/1',
    is_quiz_lti_assignment: true,
  })
  ENV.PERMISSIONS = {manage: false}
  const json = assignment.toView()
  equal(json.htmlUrl, 'http://example.com/assignments/1')
  ENV.PERMISSIONS = {}
  ENV.FLAGS = {}
})

test('includes htmlEditUrl', () => {
  const assignment = new Assignment({html_url: 'http://example.com/assignments/1'})
  const json = assignment.toView()
  equal(json.htmlEditUrl, 'http://example.com/assignments/1/edit')
})

test('includes htmlBuildUrl', () => {
  const assignment = new Assignment({html_url: 'http://example.com/assignments/1'})
  const json = assignment.toView()
  equal(json.htmlBuildUrl, 'http://example.com/assignments/1')
})

test('includes multipleDueDates', () => {
  const assignment = new Assignment({
    all_dates: [{title: 'Summer'}, {title: 'Winter'}],
  })
  const json = assignment.toView()
  equal(json.multipleDueDates, true)
})

test('includes allDates', () => {
  const assignment = new Assignment({
    all_dates: [{title: 'Summer'}, {title: 'Winter'}],
  })
  const json = assignment.toView()
  equal(json.allDates.length, 2)
})

test('includes singleSectionDueDate', () => {
  const dueAt = new Date('2013-11-27T11:01:00Z')
  const assignment = new Assignment({
    all_dates: [
      {
        due_at: null,
        title: 'Everyone',
      },
      {
        due_at: dueAt,
        title: 'Summer',
      },
    ],
  })
  sandbox.stub(assignment, 'multipleDueDates').returns(false)
  const json = assignment.toView()
  equal(json.singleSectionDueDate, dueAt.toISOString())
})

test('includes fields for isPage', () => {
  const assignment = new Assignment({submission_types: ['wiki_page']})
  const json = assignment.toView()
  notOk(json.hasDueDate)
  notOk(json.hasPointsPossible)
})

test('includes fields for isQuiz', () => {
  const assignment = new Assignment({submission_types: ['online_quiz']})
  const json = assignment.toView()
  ok(json.hasDueDate)
  notOk(json.hasPointsPossible)
})

test('returns omitFromFinalGrade', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.omitFromFinalGrade(true)
  const json = assignment.toView()
  ok(json.omitFromFinalGrade)
})

test('returns true when anonymousInstructorAnnotations is true', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.anonymousInstructorAnnotations(true)
  strictEqual(assignment.toView().anonymousInstructorAnnotations, true)
})

test('returns false when anonymousInstructorAnnotations is false', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.anonymousInstructorAnnotations(false)
  strictEqual(assignment.toView().anonymousInstructorAnnotations, false)
})

QUnit.module('Assignment#singleSection', {
  setup() {
    fakeENV.setup()
  },
  teardown() {
    fakeENV.teardown()
  },
})

test('returns null when all_dates is null', () => {
  const assignment = new Assignment({})
  sandbox.stub(assignment, 'allDates').returns(null)
  equal(assignment.singleSection(), null)
})

test('returns null when there are multiple all_dates records', () => {
  const date = new Date('2022-02-15T11:13:00')
  const assignment = new Assignment({
    all_dates: [
      {
        lock_at: date,
        unlock_at: date,
        due_at: null,
        title: 'Section A',
      },
      {
        lock_at: date,
        unlock_at: date,
        due_at: null,
        title: 'Section B',
      },
      {
        lock_at: date,
        unlock_at: date,
        due_at: null,
        title: 'Section C',
      },
    ],
  })
  equal(assignment.singleSection(), null)
})

test('returns null when there are no records in all_dates', () => {
  const assignment = new Assignment({
    all_dates: [],
  })
  equal(assignment.singleSection(), null)
})

test('returns the first element in all_dates when the length is 1', () => {
  const assignment = new Assignment({
    all_dates: [
      {
        lock_at: new Date('2022-02-15T11:13:00'),
        unlock_at: new Date('2022-02-16T11:13:00'),
        due_at: new Date('2022-02-17T11:13:00'),
        title: 'Section A',
      },
    ],
  })
  deepEqual(assignment.singleSection(), assignment.allDates()[0])
})

QUnit.module('Assignment#canDuplicate')

test('returns true if record can be duplicated', () => {
  const assignment = new Assignment({
    name: 'foo',
    can_duplicate: true,
  })
  equal(assignment.canDuplicate(), true)
})

test('returns false if record cannot be duplicated', () => {
  const assignment = new Assignment({
    name: 'foo',
    can_duplicate: false,
  })
  equal(assignment.canDuplicate(), false)
})

QUnit.module('Assignment#isDuplicating')

test('returns true if record is duplicating', () => {
  const assignment = new Assignment({
    name: 'foo',
    workflow_state: 'duplicating',
  })
  equal(assignment.isDuplicating(), true)
})

test('returns false if record is not duplicating', () => {
  const assignment = new Assignment({
    name: 'foo',
    workflow_state: 'published',
  })
  equal(assignment.isDuplicating(), false)
})

QUnit.module('Assignment#failedToDuplicate')

test('returns true if record failed to duplicate', () => {
  const assignment = new Assignment({
    name: 'foo',
    workflow_state: 'failed_to_duplicate',
  })
  equal(assignment.failedToDuplicate(), true)
})

test('returns false if record did not fail to duplicate', () => {
  const assignment = new Assignment({
    name: 'foo',
    workflow_state: 'published',
  })
  equal(assignment.failedToDuplicate(), false)
})

QUnit.module('Assignment#originalAssignmentID')

test('returns the original assignment id', () => {
  const originalAssignmentID = '42'
  const assignment = new Assignment({
    name: 'foo',
    original_assignment_id: originalAssignmentID,
  })
  equal(assignment.originalAssignmentID(), originalAssignmentID)
})

QUnit.module('Assignment#originalCourseID')

test('returns the original assignment id', () => {
  const originalCourseID = '42'
  const assignment = new Assignment({
    name: 'foo',
    original_course_id: originalCourseID,
  })
  equal(assignment.originalCourseID(), originalCourseID)
})

QUnit.module('Assignment#originalAssignmentName')

test('returns the original assignment name', () => {
  const originalAssignmentName = 'Original Assignment'
  const assignment = new Assignment({
    name: 'foo',
    original_assignment_name: originalAssignmentName,
  })
  equal(assignment.originalAssignmentName(), originalAssignmentName)
})

QUnit.module('Assignment#isQuizLTIAssignment')

test('returns true if record uses quizzes 2', () => {
  const assignment = new Assignment({
    name: 'foo',
    is_quiz_lti_assignment: true,
  })
  equal(assignment.isQuizLTIAssignment(), true)
})

test('returns false if record does not use quizzes 2', () => {
  const assignment = new Assignment({
    name: 'foo',
    is_quiz_lti_assignment: false,
  })
  equal(assignment.isQuizLTIAssignment(), false)
})

QUnit.module('Assignment#canFreeze')

test('returns true if record is not frozen', () => {
  const assignment = new Assignment({
    name: 'foo',
    frozen_attributes: [],
  })
  equal(assignment.canFreeze(), true)
})

test('returns false if record is frozen', () => {
  const assignment = new Assignment({
    name: 'foo',
    frozen_attributes: [],
    frozen: true,
  })
  equal(assignment.canFreeze(), false)
})

test('returns false if record uses quizzes 2', () => {
  const assignment = new Assignment({
    name: 'foo',
    frozen_attributes: [],
  })
  sandbox.stub(assignment, 'isQuizLTIAssignment').returns(true)
  equal(assignment.canFreeze(), false)
})

QUnit.module('Assignment#submissionTypesFrozen')

test('returns false if submission types are not in frozenAttributes', () => {
  const assignment = new Assignment({frozen_attributes: ['foo']})
  equal(assignment.submissionTypesFrozen(), false)
})

test('returns true if submission_types are in frozenAttributes', () => {
  const assignment = new Assignment({frozen_attributes: ['submission_types']})
  equal(assignment.submissionTypesFrozen(), true)
})

QUnit.module('Assignment#duplicate_failed')

test('make ajax call with right url when duplicate_failed is called', () => {
  const assignmentID = '200'
  const originalAssignmentID = '42'
  const courseID = '123'
  const originalCourseID = '234'
  const assignment = new Assignment({
    name: 'foo',
    id: assignmentID,
    original_assignment_id: originalAssignmentID,
    course_id: courseID,
    original_course_id: originalCourseID,
  })
  const spy = sandbox.spy($, 'ajaxJSON')
  assignment.duplicate_failed()
  ok(
    spy.withArgs(
      `/api/v1/courses/${originalCourseID}/assignments/${originalAssignmentID}/duplicate?target_assignment_id=${assignmentID}&target_course_id=${courseID}`
    ).calledOnce
  )
})

QUnit.module('Assignment#retry_migration')

test('make ajax call with right url when retry_migration is called', () => {
  const assignmentID = '200'
  const originalQuizID = '42'
  const courseID = '123'
  const assignment = new Assignment({
    name: 'foo',
    id: assignmentID,
    original_quiz_id: originalQuizID,
    course_id: courseID,
  })
  const spy = sandbox.spy($, 'ajaxJSON')
  assignment.retry_migration()
  ok(
    spy.withArgs(
      `/api/v1/courses/${courseID}/content_exports?export_type=quizzes2&quiz_id=${originalQuizID}&failed_assignment_id=${assignmentID}&include[]=migrated_assignment`
    ).calledOnce
  )
})

QUnit.module('Assignment#pollUntilFinishedDuplicating', {
  setup() {
    this.clock = sinon.useFakeTimers()
    this.assignment = new Assignment({workflow_state: 'duplicating'})
    sandbox.stub(this.assignment, 'fetch').returns($.Deferred().resolve())
  },
  teardown() {
    this.clock.restore()
  },
})

test('polls for updates', function () {
  this.assignment.pollUntilFinishedDuplicating()
  this.clock.tick(2000)
  notOk(this.assignment.fetch.called)
  this.clock.tick(2000)
  ok(this.assignment.fetch.called)
})

test('stops polling when the assignment has finished duplicating', function () {
  this.assignment.pollUntilFinishedDuplicating()
  this.assignment.set({workflow_state: 'unpublished'})
  this.clock.tick(3000)
  ok(this.assignment.fetch.calledOnce)
  this.clock.tick(3000)
  ok(this.assignment.fetch.calledOnce)
})

QUnit.module('Assignment#pollUntilFinishedImporting', {
  setup() {
    this.clock = sinon.useFakeTimers()
    this.assignment = new Assignment({workflow_state: 'importing'})
    sandbox.stub(this.assignment, 'fetch').returns($.Deferred().resolve())
  },
  teardown() {
    this.clock.restore()
  },
})

test('polls for updates', function () {
  this.assignment.pollUntilFinishedImporting()
  this.clock.tick(2000)
  notOk(this.assignment.fetch.called)
  this.clock.tick(2000)
  ok(this.assignment.fetch.called)
})

test('stops polling when the assignment has finished importing', function () {
  this.assignment.pollUntilFinishedImporting()
  this.assignment.set({workflow_state: 'unpublished'})
  this.clock.tick(3000)
  ok(this.assignment.fetch.calledOnce)
  this.clock.tick(3000)
  ok(this.assignment.fetch.calledOnce)
})

QUnit.module('Assignment#pollUntilFinishedMigrating', {
  setup() {
    this.clock = sinon.useFakeTimers()
    this.assignment = new Assignment({workflow_state: 'migrating'})
    sandbox.stub(this.assignment, 'fetch').returns($.Deferred().resolve())
  },
  teardown() {
    this.clock.restore()
  },
})

test('polls for updates', function () {
  this.assignment.pollUntilFinishedMigrating()
  this.clock.tick(2000)
  notOk(this.assignment.fetch.called)
  this.clock.tick(2000)
  ok(this.assignment.fetch.called)
})

test('stops polling when the assignment has finished migrating', function () {
  this.assignment.pollUntilFinishedMigrating()
  this.assignment.set({workflow_state: 'unpublished'})
  this.clock.tick(3000)
  ok(this.assignment.fetch.calledOnce)
  this.clock.tick(3000)
  ok(this.assignment.fetch.calledOnce)
})

QUnit.module('Assignment#gradersAnonymousToGraders', hooks => {
  let assignment

  hooks.beforeEach(() => {
    assignment = new Assignment()
  })

  test('returns graders_anonymous_to_graders on the record if no arguments are passed', () => {
    assignment.set('graders_anonymous_to_graders', true)
    equal(assignment.gradersAnonymousToGraders(), true)
  })

  test('sets the graders_anonymous_to_graders value if an argument is passed', () => {
    assignment.set('graders_anonymous_to_graders', true)
    assignment.gradersAnonymousToGraders(false)
    equal(assignment.gradersAnonymousToGraders(), false)
  })
})

QUnit.module('Assignment#graderCommentsVisibleToGraders', hooks => {
  let assignment

  hooks.beforeEach(() => {
    assignment = new Assignment()
  })

  test('returns grader_comments_visible_to_graders on the record if no arguments are passed', () => {
    assignment.set('grader_comments_visible_to_graders', true)
    equal(assignment.graderCommentsVisibleToGraders(), true)
  })

  test('sets the grader_comments_visible_to_graders value if an argument is passed', () => {
    assignment.set('grader_comments_visible_to_graders', true)
    assignment.graderCommentsVisibleToGraders(false)
    equal(assignment.graderCommentsVisibleToGraders(), false)
  })
})

QUnit.module('Assignment#showGradersAnonymousToGradersCheckbox', hooks => {
  let assignment

  hooks.beforeEach(() => {
    assignment = new Assignment()
  })

  test('returns false if grader_comments_visible_to_graders is false', () => {
    assignment.set('grader_comments_visible_to_graders', false)
    equal(assignment.showGradersAnonymousToGradersCheckbox(), false)
  })

  test('returns false if moderated_grading is false', () => {
    assignment.set('moderated_grading', false)
    equal(assignment.showGradersAnonymousToGradersCheckbox(), false)
  })

  test('returns false if grader_comments_visible_to_graders is false and moderated_grading is true', () => {
    assignment.set('grader_comments_visible_to_graders', false)
    assignment.set('moderated_grading', true)
    equal(assignment.showGradersAnonymousToGradersCheckbox(), false)
  })

  test('returns false if grader_comments_visible_to_graders is true and moderated_grading is false', () => {
    assignment.set('grader_comments_visible_to_graders', true)
    assignment.set('moderated_grading', false)
    equal(assignment.showGradersAnonymousToGradersCheckbox(), false)
  })

  test('returns true if grader_comments_visible_to_graders is true and moderated_grading is true', () => {
    assignment.set('grader_comments_visible_to_graders', true)
    assignment.set('moderated_grading', true)
    equal(assignment.showGradersAnonymousToGradersCheckbox(), true)
  })
})

QUnit.module('Assignment#quizzesRespondusEnabled', hooks => {
  let assignment

  hooks.beforeEach(() => {
    assignment = new Assignment()
    fakeENV.setup({current_user_roles: []})
  })

  hooks.afterEach(() => {
    fakeENV.teardown()
  })

  test('returns false if the assignment is not RLDB enabled', () => {
    fakeENV.setup({current_user_roles: ['student']})
    assignment.set('require_lockdown_browser', false)
    assignment.set('is_quiz_lti_assignment', true)
    equal(assignment.quizzesRespondusEnabled(), false)
  })

  test('returns false if the assignment is not a N.Q assignment', () => {
    fakeENV.setup({current_user_roles: ['student']})
    assignment.set('require_lockdown_browser', true)
    assignment.set('is_quiz_lti_assignment', false)
    equal(assignment.quizzesRespondusEnabled(), false)
  })

  test('returns false if the user is not a student', () => {
    fakeENV.setup({current_user_roles: ['teacher']})
    assignment.set('require_lockdown_browser', true)
    assignment.set('is_quiz_lti_assignment', true)
    equal(assignment.quizzesRespondusEnabled(), false)
  })

  test('returns true if the assignment is a RLDB enabled N.Q', () => {
    fakeENV.setup({current_user_roles: ['student']})
    assignment.set('require_lockdown_browser', true)
    assignment.set('is_quiz_lti_assignment', true)
    equal(assignment.quizzesRespondusEnabled(), true)
  })
})

QUnit.module('Assignment#externalToolTagAttributes', hooks => {
  const externalData = {
    key1: 'val1',
  }
  const customParams = {
    root_account_id: '$Canvas.rootAccount.id',
    referer: 'LTI test tool example',
  }
  let assignment

  hooks.beforeEach(() => {
    assignment = new Assignment({
      name: 'Sample Assignment',
      external_tool_tag_attributes: {
        content_id: 999,
        content_type: 'context_external_tool',
        custom_params: customParams,
        new_tab: '0',
        url: 'http://lti13testtool.docker/launch',
        external_data: externalData,
      },
    })
    fakeENV.setup({current_user_roles: []})
  })

  hooks.afterEach(() => {
    fakeENV.teardown()
  })

  test(`returns url from assignment's external tool attributes`, () => {
    const url = assignment.externalToolUrl()

    equal(url, 'http://lti13testtool.docker/launch')
  })

  test(`returns external data from assignment's external tool attributes`, () => {
    const data = assignment.externalToolData()

    equal(data.key1, 'val1')

    equal(assignment.externalToolDataStringified(), JSON.stringify(externalData))
  })

  test(`returns custom params from assignment's external tool attributes`, () => {
    equal(assignment.externalToolCustomParams(), customParams)
  })

  test(`returns custom params stringified from assignment's external tool attributtes`, () => {
    const data = assignment.externalToolCustomParamsStringified()
    equal(data, JSON.stringify(customParams))
  })

  test(`returns new tab from assignment's external tool attributes`, () => {
    equal(assignment.externalToolNewTab(), '0')
  })
})
