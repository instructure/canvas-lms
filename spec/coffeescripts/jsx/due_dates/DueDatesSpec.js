/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import React from 'react'
import ReactDOM from 'react-dom'
import TestUtils from 'react-dom/test-utils'
import {every, keys, isEmpty, intersection, map} from 'lodash'
import DueDates from 'jsx/due_dates/DueDates'
import OverrideStudentStore from 'jsx/due_dates/OverrideStudentStore'
import StudentGroupStore from 'jsx/due_dates/StudentGroupStore'
import AssignmentOverride from 'compiled/models/AssignmentOverride'
import fakeENV from 'helpers/fakeENV'

const findAllByTag = TestUtils.scryRenderedDOMComponentsWithTag
const findAllByClass = TestUtils.scryRenderedDOMComponentsWithClass

QUnit.module('DueDates', {
  setup() {
    fakeENV.setup()
    ENV.context_asset_string = 'course_1'
    this.server = sinon.fakeServer.create()
    this.override1 = new AssignmentOverride({
      name: 'Plebs',
      course_section_id: '1',
      due_at: null
    })
    this.override2 = new AssignmentOverride({
      name: 'Patricians',
      course_section_id: '2',
      due_at: '2015-04-05'
    })
    this.override3 = new AssignmentOverride({
      name: 'Students',
      student_ids: ['1', '3'],
      due_at: null
    })
    this.override4 = new AssignmentOverride({
      name: 'Reading Group One',
      group_id: '1',
      due_at: null
    })
    this.override5 = new AssignmentOverride({
      name: 'Reading Group Two',
      group_id: '2',
      due_at: '2015-05-05'
    })
    const props = {
      overrides: [this.override1, this.override2, this.override3, this.override4, this.override5],
      defaultSectionId: '0',
      sections: [{attributes: {id: 1, name: 'Plebs'}}, {attributes: {id: 2, name: 'Patricians'}}],
      students: {
        1: {id: '1', name: 'Scipio Africanus'},
        2: {id: '2', name: 'Cato The Elder'},
        3: {id: 3, name: 'Publius Publicoa'}
      },
      groups: {1: {id: '1', name: 'Reading Group One'}, 2: {id: '2', name: 'Reading Group Two'}},
      overrideModel: AssignmentOverride,
      syncWithBackbone() {},
      hasGradingPeriods: false,
      gradingPeriods: [],
      isOnlyVisibleToOverrides: false,
      dueAt: null
    }
    this.syncWithBackboneStub = sandbox.stub(props, 'syncWithBackbone')
    const DueDatesElement = <DueDates {...props} />
    this.dueDates = ReactDOM.render(DueDatesElement, $('<div>').appendTo('body')[0])
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.dueDates).parentNode)
    this.server.restore()
    fakeENV.teardown()
  }
})

test('renders', function() {
  ok(this.dueDates)
})

test('formats sectionHash properly', function() {
  equal(this.dueDates.state.sections[1].name, 'Plebs')
})

test('overrides with different dates are sorted into separate rows', function() {
  const sortedOverrides = map(this.dueDates.state.rows, r => r.overrides)
  ok(sortedOverrides[0].includes(this.override1))
  ok(sortedOverrides[0].includes(this.override3))
  ok(sortedOverrides[0].includes(this.override4))
  ok(sortedOverrides[1].includes(this.override2))
  ok(sortedOverrides[2].includes(this.override5))
})

test('syncs with backbone on update', function() {
  const initialCount = this.syncWithBackboneStub.callCount
  this.dueDates.setState({rows: {}})
  equal(this.syncWithBackboneStub.callCount, initialCount + 1)
})

test('will add multiple rows of overrides if AddRow is called', function() {
  equal(this.dueDates.sortedRowKeys().length, 3)
  this.dueDates.addRow()
  equal(this.dueDates.sortedRowKeys().length, 4)
  this.dueDates.addRow()
  equal(this.dueDates.sortedRowKeys().length, 5)
})

test('will filter out picked sections from validDropdownOptions', function() {
  ok(
    !this.dueDates
      .validDropdownOptions()
      .map(opt => opt.name)
      .includes('Patricians')
  )
  this.dueDates.setState({rows: {1: {overrides: []}}})
  ok(
    this.dueDates
      .validDropdownOptions()
      .map(opt => opt.name)
      .includes('Patricians')
  )
})

test('properly removes a row', function() {
  this.dueDates.setState({
    rows: {
      '1': {},
      '2': {}
    }
  })
  equal(this.dueDates.sortedRowKeys().length, 2)
  equal(this.dueDates.removeRow('2'))
  equal(this.dueDates.sortedRowKeys().length, 1)
})

test('will not allow removing the last row', function() {
  this.dueDates.setState({
    rows: {
      '1': {},
      '2': {}
    }
  })
  equal(this.dueDates.sortedRowKeys().length, 2)
  ok(this.dueDates.canRemoveRow())
  equal(this.dueDates.removeRow('2'))
  equal(this.dueDates.sortedRowKeys().length, 1)
  ok(!this.dueDates.canRemoveRow())
  equal(this.dueDates.removeRow('1'))
  equal(this.dueDates.sortedRowKeys().length, 1)
})

test('defaultSection namer shows Everyone Else if a section or student is selected', function() {
  equal(this.dueDates.defaultSectionNamer('0'), 'Everyone Else')
})

test('defaultSection namer shows Everyone if no token is selected', function() {
  this.dueDates.setState({rows: {}})
  equal(this.dueDates.defaultSectionNamer('0'), 'Everyone')
})

test('can replace the dates of a row properly', function() {
  const initialDueAts = map(this.dueDates.state.rows, row => row.dates.due_at)
  ok(!initialDueAts.every(due_at_val => due_at_val === null))
  this.dueDates.sortedRowKeys().forEach(key => this.dueDates.replaceDate(key, 'due_at', null))
  const updatedDueAts = map(this.dueDates.state.rows, row => row.dates.due_at)
  ok(updatedDueAts.every(due_at_val => due_at_val === null))
})

test('focuses on the new row begin added', function() {
  sandbox.spy(this.dueDates, 'focusRow')
  this.dueDates.addRow()
  equal(this.dueDates.focusRow.callCount, 1)
})

test('filters available groups based on selected group category', function() {
  const groups = [
    {
      id: '3',
      group_category_id: '1'
    },
    {
      id: '4',
      group_category_id: '2'
    }
  ]
  StudentGroupStore.setSelectedGroupSet(null)
  StudentGroupStore.addGroups(groups)
  ok(
    !this.dueDates
      .validDropdownOptions()
      .map(opt => opt.group_id)
      .includes('3')
  )
  ok(
    !this.dueDates
      .validDropdownOptions()
      .map(opt => opt.group_id)
      .includes('4')
  )
  StudentGroupStore.setSelectedGroupSet('1')
  ok(
    this.dueDates
      .validDropdownOptions()
      .map(opt => opt.group_id)
      .includes('3')
  )
  ok(
    !this.dueDates
      .validDropdownOptions()
      .map(opt => opt.group_id)
      .includes('4')
  )
  StudentGroupStore.setSelectedGroupSet('2')
  ok(
    !this.dueDates
      .validDropdownOptions()
      .map(opt => opt.group_id)
      .includes('3')
  )
  ok(
    this.dueDates
      .validDropdownOptions()
      .map(opt => opt.group_id)
      .includes('4')
  )
})

test('includes the persisted state on the overrides', function() {
  const attributes = keys(this.dueDates.getAllOverrides()[0].attributes)
  ok(attributes.includes('persisted'))
})

QUnit.module('DueDates with grading periods', {
  setup() {
    fakeENV.setup()
    this.server = sinon.fakeServer.create()
    ENV.context_asset_string = 'course_1'
    ENV.current_user_roles = ['teacher']
    const overrides = [
      new AssignmentOverride({
        id: '70',
        assignment_id: '64',
        title: 'Section 1',
        due_at: '2014-07-16T05:59:59Z',
        all_day: true,
        all_day_date: '2014-07-16',
        unlock_at: null,
        lock_at: null,
        course_section_id: '19',
        due_at_overridden: true,
        unlock_at_overridden: true,
        lock_at_overridden: true
      }),
      new AssignmentOverride({
        id: '71',
        assignment_id: '64',
        title: '1 student',
        due_at: '2014-07-17T05:59:59Z',
        all_day: true,
        all_day_date: '2014-07-17',
        unlock_at: null,
        lock_at: null,
        student_ids: ['2'],
        due_at_overridden: true,
        unlock_at_overridden: true,
        lock_at_overridden: true
      }),
      new AssignmentOverride({
        id: '72',
        assignment_id: '64',
        title: '1 student',
        due_at: '2014-07-18T05:59:59Z',
        all_day: true,
        all_day_date: '2014-07-18',
        unlock_at: null,
        lock_at: null,
        student_ids: ['4'],
        due_at_overridden: true,
        unlock_at_overridden: true,
        lock_at_overridden: true
      })
    ]
    const sections = [
      { attributes: { id: "0", name: "Everyone" } },
      { attributes: { id: "19", name: "Section 1", start_at: null, end_at: null, override_course_and_term_dates: null } },
      { attributes: { id: "4", name: "Section 2", start_at: null, end_at: null, override_course_and_term_dates: null } },
      { attributes: { id: "7", name: "Section 3", start_at: null, end_at: null, override_course_and_term_dates: null } },
      { attributes: { id: "8", name: "Section 4", start_at: null, end_at: null, override_course_and_term_dates: null } },
    ]
    const gradingPeriods = [
      {
        id: '101',
        title: 'Account Closed Period',
        startDate: new Date('2014-07-01T06:00:00.000Z'),
        endDate: new Date('2014-08-31T06:00:00.000Z'),
        closeDate: new Date('2014-08-31T06:00:00.000Z'),
        isLast: false,
        isClosed: true
      },
      {
        id: '127',
        title: 'Account Open Period',
        startDate: new Date('2014-09-01T06:00:00.000Z'),
        endDate: new Date('2014-12-15T07:00:00.000Z'),
        closeDate: new Date('2014-12-15T07:00:00.000Z'),
        isLast: true,
        isClosed: false
      }
    ]
    const students = {
      1: {
        id: '1',
        name: 'Scipio Africanus',
        sections: ['19'],
        group_ids: []
      },
      2: {
        id: '2',
        name: 'Cato The Elder',
        sections: ['4'],
        group_ids: []
      },
      3: {
        id: '3',
        name: 'Publius Publicoa',
        sections: ['4'],
        group_ids: []
      },
      4: {
        id: '4',
        name: 'Louie Anderson',
        sections: ['8'],
        group_ids: []
      }
    }
    sandbox.stub(OverrideStudentStore, 'getStudents').returns(students)
    sandbox.stub(OverrideStudentStore, 'currentlySearching').returns(false)
    sandbox.stub(OverrideStudentStore, 'allStudentsFetched').returns(true)
    const props = {
      overrides,
      overrideModel: AssignmentOverride,
      defaultSectionId: '0',
      sections,
      groups: {
        1: {
          id: '1',
          name: 'Reading Group One'
        },
        2: {
          id: '2',
          name: 'Reading Group Two'
        }
      },
      syncWithBackbone() {},
      hasGradingPeriods: true,
      gradingPeriods,
      isOnlyVisibleToOverrides: true,
      dueAt: null
    }
    this.syncWithBackboneStub = sandbox.stub(props, 'syncWithBackbone')
    const DueDatesElement = <DueDates {...props} />
    this.dueDates = ReactDOM.render(DueDatesElement, $('<div>').appendTo('body')[0])
    this.dueDates.handleStudentStoreChange()
    this.dropdownOptions = this.dueDates.validDropdownOptions().map(opt => opt.name)
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.dueDates).parentNode)
    this.server.restore()
    fakeENV.teardown()
  }
})

test('sets inputs to readonly for overrides in closed grading periods', function() {
  const inputs = findAllByTag(this.dueDates, 'input')
  ok(every(inputs, input => input.readOnly))
})

test('disables the datepicker button for overrides in closed grading periods', function() {
  const buttons = findAllByClass(this.dueDates, 'Button--icon-action')
  ok(every(buttons, button => button.className.match('disabled')))
})

test('dropdown options do not include sections assigned in closed periods', function() {
  notOk(this.dropdownOptions.includes('Section 1'))
})

test('dropdown options do not include students assigned in closed periods', function() {
  notOk(this.dropdownOptions.includes('Cato The Elder'))
})

test('dropdown options do not include sections with any students assigned in closed periods', function() {
  ok(isEmpty(intersection(this.dropdownOptions, ['Section 2', 'Section 4'])))
})

test('dropdown options do not include students whose sections are assigned in closed periods', function() {
  notOk(this.dropdownOptions.includes('Scipio Africanus'))
})

test('dropdown options include sections that are not assigned in closed periods and do not have any students assigned in closed periods', function() {
  ok(this.dropdownOptions.includes('Section 3'))
})

test('dropdown options include students that do not belong to sections assigned in closed periods', function() {
  ok(this.dropdownOptions.includes('Publius Publicoa'))
})

QUnit.module('DueDates render callbacks', {
  setup() {
    fakeENV.setup()
    this.server = sinon.fakeServer.create()
    ENV.context_asset_string = 'course_1'
    this.override = new AssignmentOverride({
      name: 'Students',
      student_ids: ['1', '3'],
      due_at: null
    })

    this.dueDates

    this.props = {
      overrides: [this.override],
      defaultSectionId: '0',
      sections: [],
      students: {
        '1': {
          id: '1',
          name: 'Scipio Africanus'
        },
        '3': {
          id: 3,
          name: 'Publius Publicoa'
        }
      },
      overrideModel: AssignmentOverride,
      syncWithBackbone() {},
      hasGradingPeriods: false,
      gradingPeriods: [],
      isOnlyVisibleToOverrides: false,
      dueAt: null
    }
  },
  teardown() {
    this.server.restore()
    fakeENV.teardown()
  }
})

test('fetchAdhocStudents does not fire until state is set', function() {
  const fetchAdhocStudentsStub = sandbox.stub(OverrideStudentStore, 'fetchStudentsByID')
  const DueDatesElement = <DueDates {...this.props} />

  // render with the props (which should provide info for fetchStudentsByID call)
  this.dueDates = ReactDOM.render(DueDatesElement, $('<div>').appendTo('body')[0])
  this.dueDates.setState({
    rows: [
      {
        1: {
          overrides: {
            student_ids: ['18', '22']
          }
        }
      }
    ],
    students: {}
  })

  notOk(fetchAdhocStudentsStub.calledWith(['18', '22']))
  ok(fetchAdhocStudentsStub.calledWith(['1', '3']))

  ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.dueDates).parentNode)
})
