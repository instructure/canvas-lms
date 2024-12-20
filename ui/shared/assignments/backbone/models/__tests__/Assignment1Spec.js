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

import 'jquery-migrate'
import '@canvas/jquery/jquery.ajaxJSON'
import Assignment from '../Assignment'
import fakeENV from '@canvas/test-utils/fakeENV'

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
