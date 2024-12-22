/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import fakeENV from '@canvas/test-utils/fakeENV'
import Assignment from '../Assignment'

describe('Assignment', () => {
  describe('POST_TO_SIS behavior', () => {
    describe('when ENV.POST_TO_SIS is false', () => {
      beforeEach(() => {
        fakeENV.setup({POST_TO_SIS: false})
      })

      afterEach(() => {
        fakeENV.teardown()
      })

      it('does not alter the post_to_sis field', () => {
        const assignment = new Assignment()
        expect(assignment.get('post_to_sis')).toBeUndefined()
      })
    })

    describe('when ENV.POST_TO_SIS is true', () => {
      beforeEach(() => {
        fakeENV.setup({
          POST_TO_SIS: true,
          POST_TO_SIS_DEFAULT: true,
        })
      })

      afterEach(() => {
        fakeENV.teardown()
      })

      it('defaults post_to_sis to true for a new assignment', () => {
        const assignment = new Assignment()
        expect(assignment.get('post_to_sis')).toBe(true)
      })

      it('preserves a false value', () => {
        const assignment = new Assignment({post_to_sis: false})
        expect(assignment.get('post_to_sis')).toBe(false)
      })

      it('preserves a null value for an existing assignment', () => {
        const assignment = new Assignment({
          id: '1234',
          post_to_sis: null,
        })
        expect(assignment.get('post_to_sis')).toBeNull()
      })
    })
  })

  describe('submission type detection', () => {
    it('identifies quiz assignments', () => {
      const assignment = new Assignment({name: 'foo'})
      assignment.set('submission_types', ['online_quiz'])
      expect(assignment.isQuiz()).toBe(true)

      assignment.set('submission_types', ['on_paper'])
      expect(assignment.isQuiz()).toBe(false)
    })

    it('identifies discussion topic assignments', () => {
      const assignment = new Assignment({name: 'foo'})
      assignment.submissionTypes(['discussion_topic'])
      expect(assignment.isDiscussionTopic()).toBe(true)

      assignment.submissionTypes(['on_paper'])
      expect(assignment.isDiscussionTopic()).toBe(false)
    })

    it('identifies external tool assignments', () => {
      const assignment = new Assignment({name: 'foo'})
      assignment.submissionTypes(['external_tool'])
      expect(assignment.isExternalTool()).toBe(true)

      assignment.submissionTypes(['on_paper'])
      expect(assignment.isExternalTool()).toBe(false)
    })

    it('identifies not graded assignments', () => {
      const assignment = new Assignment({name: 'foo'})
      assignment.submissionTypes(['not_graded'])
      expect(assignment.isNotGraded()).toBe(true)

      assignment.gradingType('percent')
      assignment.submissionTypes(['online_url'])
      expect(assignment.isNotGraded()).toBe(false)
    })
  })

  describe('default submission types', () => {
    beforeEach(() => {
      fakeENV.setup({
        DEFAULT_ASSIGNMENT_TOOL_NAME: 'Default Tool',
        DEFAULT_ASSIGNMENT_TOOL_URL: 'https://www.test.com/blti',
      })
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('handles none submission type', () => {
      const assignment = new Assignment({name: 'foo'})
      assignment.submissionTypes(['none'])
      expect(assignment.defaultToNone()).toBe(true)

      const newAssignment = new Assignment()
      expect(newAssignment.defaultToNone()).toBe(false)
    })

    it('handles online submission type', () => {
      const assignment = new Assignment({name: 'foo'})
      assignment.submissionTypes(['online'])
      expect(assignment.defaultToOnline()).toBe(true)

      const newAssignment = new Assignment()
      expect(newAssignment.defaultToOnline()).toBe(false)
    })

    it('handles on_paper submission type', () => {
      const assignment = new Assignment({name: 'foo'})
      assignment.submissionTypes(['on_paper'])
      expect(assignment.defaultToOnPaper()).toBe(true)

      const newAssignment = new Assignment()
      expect(newAssignment.defaultToOnPaper()).toBe(false)
    })
  })

  describe('external tool behavior', () => {
    beforeEach(() => {
      fakeENV.setup({
        DEFAULT_ASSIGNMENT_TOOL_NAME: 'Default Tool',
        DEFAULT_ASSIGNMENT_TOOL_URL: 'https://www.test.com/blti',
      })
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('identifies default external tool assignments', () => {
      const assignment = new Assignment({
        name: 'foo',
        external_tool_tag_attributes: {
          url: 'https://www.test.com/blti?foo',
        },
      })
      assignment.submissionTypes(['external_tool'])
      expect(assignment.isDefaultTool()).toBe(true)

      const defaultTypeAssignment = new Assignment({name: 'foo'})
      defaultTypeAssignment.submissionTypes(['default_external_tool'])
      expect(defaultTypeAssignment.isDefaultTool()).toBe(true)
    })

    it('identifies generic external tool assignments', () => {
      const assignment = new Assignment({
        name: 'foo',
        external_tool_tag_attributes: {
          url: 'https://www.non-default.com/blti?foo',
        },
      })
      assignment.submissionTypes(['external_tool'])
      expect(assignment.isGenericExternalTool()).toBe(true)

      const plainAssignment = new Assignment({name: 'foo'})
      plainAssignment.submissionTypes(['external_tool'])
      expect(plainAssignment.isGenericExternalTool()).toBe(true)
    })
  })

  describe('default tool name handling', () => {
    describe('with HTML in tool name', () => {
      beforeEach(() => {
        fakeENV.setup({
          DEFAULT_ASSIGNMENT_TOOL_NAME: 'Default Tool <a href="https://www.somethingbad.com">',
        })
      })

      afterEach(() => {
        fakeENV.teardown()
      })

      it('escapes HTML in the tool name', () => {
        const assignment = new Assignment({name: 'foo'})
        expect(assignment.defaultToolName()).toBe(
          'Default Tool %3Ca href%3D%22https%3A//www.somethingbad.com%22%3E',
        )
      })
    })

    describe('with undefined tool name', () => {
      beforeEach(() => {
        fakeENV.setup({
          DEFAULT_ASSIGNMENT_TOOL_NAME: undefined,
        })
      })

      afterEach(() => {
        fakeENV.teardown()
      })

      it('preserves undefined value', () => {
        const assignment = new Assignment({name: 'foo'})
        expect(assignment.defaultToolName()).toBeUndefined()
      })
    })
  })

  describe('assignment type handling', () => {
    describe('as a setter', () => {
      it('sets submission_types to the provided value', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set('submission_types', 'online_quiz')
        assignment.assignmentType('discussion_topic')
        expect(assignment.assignmentType()).toBe('discussion_topic')
        expect(assignment.get('submission_types')).toEqual(['discussion_topic'])
      })

      it('sets submission_types to none when value is assignment', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set('submission_types', 'online_quiz')
        assignment.assignmentType('assignment')
        expect(assignment.assignmentType()).toBe('assignment')
        expect(assignment.get('submission_types')).toEqual(['none'])
      })
    })

    describe('as a getter', () => {
      it('returns assignment for standard submission types', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set('submission_types', ['on_paper'])
        expect(assignment.assignmentType()).toBe('assignment')
      })

      it('returns specific type for non-standard assignments', () => {
        const assignment = new Assignment({name: 'foo'})
        assignment.set('submission_types', ['online_quiz'])
        expect(assignment.assignmentType()).toBe('online_quiz')
      })
    })
  })

  describe('date handling', () => {
    it('gets and sets due_at', () => {
      const date = Date.now()
      const assignment = new Assignment({name: 'foo'})
      assignment.set('due_at', null)
      assignment.dueAt(date)
      expect(assignment.dueAt()).toBe(date)
    })

    it('gets unlock_at', () => {
      const date = Date.now()
      const assignment = new Assignment({name: 'foo'})
      assignment.set('unlock_at', date)
      expect(assignment.unlockAt()).toBe(date)
    })
  })

  describe('moderated grading', () => {
    it('handles moderated grading settings', () => {
      const assignment = new Assignment()
      expect(assignment.moderatedGrading()).toBe(false)

      const unmoderatedAssignment = new Assignment({moderated_grading: false})
      expect(unmoderatedAssignment.moderatedGrading()).toBe(false)

      const moderatedAssignment = new Assignment({moderated_grading: true})
      expect(moderatedAssignment.moderatedGrading()).toBe(true)
    })
  })
})
