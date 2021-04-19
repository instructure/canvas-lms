/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import _ from 'underscore'

import tz from '@canvas/timezone'
import AssignmentOverrideHelper from '@canvas/due-dates/AssignmentOverrideHelper'

const students = [
  {id: '1', group_ids: ['1'], sections: ['1']},
  {id: '2', group_ids: ['2'], sections: ['1']},
  {id: '3', group_ids: ['2'], sections: ['2']},
  {id: '4', group_ids: ['3'], sections: ['3']}
]

function createOverride({type, id, dueAt} = {}) {
  const override = {
    assignment_id: '1',
    due_at: dueAt
  }

  if (type === 'student') {
    override.student_ids = [id]
  } else if (type === 'section') {
    override.course_section_id = id
  } else {
    override.group_id = id
  }

  return override
}

QUnit.module(
  'AssignmentOverrideHelper#effectiveDueDatesForAssignment - assignment only visible to overrides',
  {
    setup() {
      this.dates = {
        june: new Date('2009-06-03T02:57:42.000Z'),
        august: new Date('2009-08-03T02:57:42.000Z'),
        october: new Date('2009-10-03T02:57:42.000Z')
      }

      this.assignment = {due_at: null, only_visible_to_overrides: true}
      this.overrides = [
        createOverride({type: 'student', id: '1', dueAt: this.dates.june}),
        createOverride({type: 'section', id: '1', dueAt: this.dates.august}),
        createOverride({type: 'group', id: '1', dueAt: this.dates.october})
      ]

      this.dueDates = AssignmentOverrideHelper.effectiveDueDatesForAssignment(
        this.assignment,
        this.overrides,
        students
      )
    }
  }
)

test('returns dates for assigned students', function() {
  const studentIDs = _.keys(this.dueDates)
  propEqual(studentIDs, ['1', '2'])
})

test('returns the most lenient (most time to turn in) applicable date for each student', function() {
  const effectiveDates = _.map(this.dueDates, date => date.getTime())
  propEqual(effectiveDates, [this.dates.october.getTime(), this.dates.august.getTime()])
})

QUnit.module(
  'AssignmentOverrideHelper#effectiveDueDatesForAssignment - assignment visible to all students',
  {
    setup() {
      this.dates = {
        june: new Date('2009-06-03T02:57:42.000Z'),
        may: new Date('2009-05-03T02:57:42.000Z')
      }

      this.assignment = {due_at: this.dates.may, only_visible_to_overrides: false}
      this.overrides = [createOverride({type: 'student', id: '1', dueAt: this.dates.june})]

      this.dueDates = AssignmentOverrideHelper.effectiveDueDatesForAssignment(
        this.assignment,
        this.overrides,
        students
      )
    }
  }
)

test('returns dates for assigned students', function() {
  const studentIDs = _.keys(this.dueDates)
  propEqual(studentIDs, _.pluck(students, 'id'))
})

test('returns the assignment due date for students without overrides', function() {
  equal(this.dueDates[2].getTime(), this.dates.may.getTime())
})

QUnit.module(
  'AssignmentOverrideHelper#effectiveDueDatesForAssignment - students without sections and group_ids',
  {
    setup() {
      this.assignment = {
        due_at: new Date('2009-05-03T02:57:42.000Z'),
        only_visible_to_overrides: false
      }
      this.overrides = []
    }
  }
)

test('does not throw an error if students do not have a `sections` attribute', function() {
  const students = [{id: '1', group_ids: ['3']}]
  let errorThrown = false

  try {
    AssignmentOverrideHelper.effectiveDueDatesForAssignment(
      this.assignment,
      this.overrides,
      students
    )
  } catch (e) {
    errorThrown = true
  }

  notOk(errorThrown)
})

test('does not throw an error if students do not have a `group_ids` attribute', function() {
  const students = [{id: '1', sections: ['1']}]
  let errorThrown = false

  try {
    AssignmentOverrideHelper.effectiveDueDatesForAssignment(
      this.assignment,
      this.overrides,
      students
    )
  } catch (e) {
    errorThrown = true
  }

  notOk(errorThrown)
})
