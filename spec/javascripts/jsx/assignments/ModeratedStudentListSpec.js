/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import React from 'react'
import {mount} from 'enzyme'
import ModeratedStudentList from 'jsx/assignments/ModeratedStudentList'

function fakeStudentList() {
  return {
    students: [
      {
        id: '3',
        display_name: 'a@example.edu',
        avatar_image_url: 'https://canvas.instructure.com/images/messages/avatar-50.png',
        html_url: 'http://localhost:3000/courses/1/users/3',
        in_moderation_set: false,
        selected_provisional_grade_id: null,
        provisional_grades: [
          {
            grade: '4',
            score: 4,
            graded_at: '2015-09-11T15:42:28Z',
            scorer_id: '1',
            final: false,
            provisional_grade_id: '10',
            grade_matches_current_submission: true,
            speedgrader_url: 'speedgraderUrl'
          }
        ]
      }
    ]
  }
}

function fakeUngradedStudentList() {
  return {
    students: [
      {
        id: '3',
        display_name: 'a@example.edu',
        avatar_image_url: 'https://canvas.instructure.com/images/messages/avatar-50.png',
        html_url: 'http://localhost:3000/courses/1/users/3',
        in_moderation_set: false,
        selected_provisional_grade_id: null
      }
    ]
  }
}

QUnit.module('ModeratedStudentList')

test('renders provisional scores i18ned', function() {
  const newFakeStudentList = fakeStudentList()
  const firstStudent = newFakeStudentList.students[0]
  firstStudent.in_moderation_set = true
  firstStudent.provisional_grades[0].score = 4000.1
  const props = {
    urls: {
      assignment_speedgrader_url: 'speedgraderUrl'
    },
    includeModerationSetColumns: true,
    studentList: newFakeStudentList,
    assignment: {
      published: true,
      course_id: '1'
    },
    handleCheckbox: this.stub(),
    onSelectProvisionalGrade: this.stub()
  }

  const wrapper = mount(
    <table>
      <ModeratedStudentList {...props} />
    </table>
  )
  const moderatedColumns = wrapper.find('.ModeratedAssignmentList__Mark')

  equal(moderatedColumns.at(0).text(), '4,000.1')

  wrapper.unmount()
})

test('renders final scores i18ned', function() {
  const newFakeStudentList = fakeStudentList()
  const firstStudent = newFakeStudentList.students[0]
  firstStudent.in_moderation_set = true
  firstStudent.provisional_grades[0].score = 4000.1
  firstStudent.provisional_grades[0].final = true
  const props = {
    urls: {
      assignment_speedgrader_url: 'speedgraderUrl'
    },
    includeModerationSetColumns: true,
    studentList: newFakeStudentList,
    assignment: {
      published: true,
      course_id: '1'
    },
    handleCheckbox: () => {},
    onSelectProvisionalGrade: () => {}
  }

  const wrapper = mount(
    <table>
      <ModeratedStudentList {...props} />
    </table>
  )
  const gradeColumns = wrapper.find('.AssignmentList_Grade')

  equal(gradeColumns.at(0).text(), '4,000.1')

  wrapper.unmount()
})

test('only shows the next speedgrader link when in moderation set', function() {
  const newFakeStudentList = fakeStudentList()
  newFakeStudentList.students[0].in_moderation_set = true
  const props = {
    urls: {
      assignment_speedgrader_url: 'speedgraderUrl'
    },
    includeModerationSetColumns: true,
    studentList: newFakeStudentList,
    assignment: {
      published: true,
      course_id: '1'
    },
    handleCheckbox: () => {},
    onSelectProvisionalGrade: () => {}
  }

  const wrapper = mount(
    <table>
      <ModeratedStudentList {...props} />
    </table>
  )
  const moderatedColumns = wrapper.find('.ModeratedAssignmentList__Mark')
  const columns = wrapper.find('.AssignmentList__Mark')

  equal(moderatedColumns.at(0).text(), '4', 'displays the grade in the first column')
  equal(moderatedColumns.at(1).text(), 'SpeedGrader™', 'displays speedgrader link in the second')
  equal(columns.at(0).text(), '-', 'third column is a dash')

  wrapper.unmount()
})

test('show a dash in in the first column when not in the moderation set', function() {
  const newFakeStudentList = fakeStudentList()
  const props = {
    urls: {
      assignment_speedgrader_url: 'speedgraderUrl'
    },
    includeModerationSetColumns: true,
    studentList: newFakeStudentList,
    assignment: {
      published: false,
      course_id: '1'
    },
    handleCheckbox: () => {},
    onSelectProvisionalGrade: () => {}
  }

  const wrapper = mount(
    <table>
      <ModeratedStudentList {...props} />
    </table>
  )
  const columns = wrapper.find('.AssignmentList__Mark')

  equal(columns.at(0).text(), '-', 'shows a dash for non moderation set students')

  wrapper.unmount()
})

test('only shows one column when includeModerationSetHeaders is false', function() {
  const props = {
    urls: {
      assignment_speedgrader_url: 'speedgraderUrl'
    },
    includeModerationSetColumns: false,
    studentList: fakeStudentList(),
    assignment: {
      published: false,
      course_id: '1'
    },
    handleCheckbox: () => {},
    onSelectProvisionalGrade: () => {}
  }

  const wrapper = mount(
    <table>
      <ModeratedStudentList {...props} />
    </table>
  )
  const columns = wrapper.find('.AssignmentList__Mark')
  const moderatedColumns = wrapper.find('.ModeratedAssignmentList__Mark')

  equal(columns.length, 1, 'only show one column')
  equal(moderatedColumns.length, 0, 'no moderated columns shown')

  wrapper.unmount()
})

test('shows the grade column when there is a selected_provisional_grade_id', function() {
  const newFakeStudentList = fakeStudentList()
  newFakeStudentList.students[0].selected_provisional_grade_id = 10
  const props = {
    urls: {
      assignment_speedgrader_url: 'speedgraderUrl'
    },
    includeModerationSetColumns: true,
    studentList: newFakeStudentList,
    assignment: {
      published: false,
      course_id: '1'
    },
    handleCheckbox: () => {},
    onSelectProvisionalGrade: () => {}
  }

  const wrapper = mount(
    <table>
      <ModeratedStudentList {...props} />
    </table>
  )
  const gradeColumns = wrapper.find('.AssignmentList_Grade')

  equal(gradeColumns.at(0).text(), '4')

  wrapper.unmount()
})

test('properly renders final grade if there are no provisional grades', function() {
  const newFakeStudentList = fakeUngradedStudentList()
  const props = {
    urls: {
      assignment_speedgrader_url: 'speedgraderUrl'
    },
    includeModerationSetColumns: true,
    studentList: newFakeStudentList,
    assignment: {
      published: false,
      course_id: '1'
    },
    handleCheckbox: () => {},
    onSelectProvisionalGrade: () => {}
  }

  const wrapper = mount(
    <table>
      <ModeratedStudentList {...props} />
    </table>
  )
  const gradeColumns = wrapper.find('.AssignmentList_Grade')

  equal(gradeColumns.at(0).text(), '-', 'grade column is a dash')

  wrapper.unmount()
})

test('does not show radio button if there is only one provisional grade', function() {
  const newFakeStudentList = fakeStudentList()
  const props = {
    urls: {
      assignment_speedgrader_url: 'speedgraderUrl'
    },
    includeModerationSetColumns: true,
    studentList: newFakeStudentList,
    assignment: {
      published: false,
      course_id: '1'
    },
    handleCheckbox: () => {},
    onSelectProvisionalGrade: () => {}
  }

  const wrapper = mount(
    <table>
      <ModeratedStudentList {...props} />
    </table>
  )
  const radioInputs = wrapper.find('input[type="radio"]')

  equal(radioInputs.length, 0, 'does not render any radio buttons')

  wrapper.unmount()
})

test('shows radio button if there is more than 1 provisional grade', function() {
  const newFakeStudentList = fakeStudentList()
  newFakeStudentList.students[0].provisional_grades.push({
    grade: '4',
    score: 4,
    graded_at: '2015-09-11T15:42:28Z',
    scorer_id: '1',
    final: false,
    provisional_grade_id: '11',
    grade_matches_current_submission: true,
    speedgrader_url: 'speedgraderUrl'
  })

  const props = {
    urls: {
      assignment_speedgrader_url: 'speedgraderUrl'
    },
    includeModerationSetColumns: true,
    studentList: newFakeStudentList,
    assignment: {
      published: false,
      course_id: '1'
    },
    handleCheckbox: () => {},
    onSelectProvisionalGrade: () => {}
  }

  const wrapper = mount(
    <table>
      <ModeratedStudentList {...props} />
    </table>
  )
  const radioInputs = wrapper.find('input[type="radio"]')

  equal(radioInputs.length, 2, 'renders two radio buttons')

  wrapper.unmount()
})

QUnit.module('Persist provisional grades')

test('selecting provisional grade triggers handleSelectProvisionalGrade handler', function() {
  const newFakeStudentList = fakeStudentList()
  newFakeStudentList.students[0].provisional_grades.push({
    grade: '4',
    score: 4,
    graded_at: '2015-09-11T15:42:28Z',
    scorer_id: '1',
    final: false,
    provisional_grade_id: '11',
    grade_matches_current_submission: true,
    speedgrader_url: 'speedgraderUrl'
  })
  newFakeStudentList.students[0].in_moderation_set = true
  const callback = this.spy()
  const props = {
    onSelectProvisionalGrade: callback,
    urls: {
      provisional_grades_base_url: 'blah'
    },
    includeModerationSetColumns: true,
    studentList: newFakeStudentList,
    assignment: {
      published: false,
      course_id: '1'
    },
    handleCheckbox: () => {}
  }

  const wrapper = mount(
    <table>
      <ModeratedStudentList {...props} />
    </table>
  )
  const radioInputs = wrapper.find('input[type="radio"]')

  radioInputs.at(0).simulate('change')

  ok(callback.called, 'called selectProvisionalGrade')

  wrapper.unmount()
})
