/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {
  createGradebook,
  setFixtureHtml,
} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'

const $fixtures = document.getElementById('fixtures')

QUnit.module('Gradebook', suiteHooks => {
  let $container
  let gradebook

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
    setFixtureHtml($container)
  })

  suiteHooks.afterEach(() => {
    gradebook.destroy()
    $container.remove()
  })

  QUnit.module('Gradebook#studentSearchMatcher', hooks => {
    hooks.beforeEach(() => {
      gradebook = createGradebook()
      const students = [
        {
          id: '1303',
          name: 'Joe Dirt',
          sis_user_id: 'meteor',
          enrollments: [{type: 'StudentEnrollment', grades: {html_url: 'http://example.url/'}}],
        },
      ]
      gradebook.courseContent.students.setStudentIds(['1303'])
      gradebook.gotChunkOfStudents(students)
    })

    test('returns true if the search term is a substring of the student name (case insensitive)', () => {
      const option = {id: '1303', label: 'Joe Dirt'}
      ok(gradebook.studentSearchMatcher(option, 'dir'))
    })

    test('returns false if the search term is not a substring of the student name', () => {
      const option = {id: '1303', label: 'Joe Dirt'}
      notOk(gradebook.studentSearchMatcher(option, 'Dirz'))
    })

    test('returns true if the search term matches the SIS ID exactly (case insensitive)', () => {
      const option = {id: '1303', label: 'Joe Dirt'}
      ok(gradebook.studentSearchMatcher(option, 'Meteor'))
    })

    test('returns false if the search term is a substring of the SIS ID, but does not match exactly', () => {
      const option = {id: '1303', label: 'Joe Dirt'}
      notOk(gradebook.studentSearchMatcher(option, 'meteo'))
    })

    test('does not treat the search term as a regular expression', () => {
      const option = {id: '1303', label: 'Joe Dirt'}
      notOk(gradebook.studentSearchMatcher(option, 'Joe.*rt'))
    })
  })

  QUnit.module('#_updateEssentialDataLoaded()', () => {
    function createInitializedGradebook(options) {
      gradebook = createGradebook(options)
      sinon.stub(gradebook, 'finishRenderingUI')

      gradebook.setStudentIdsLoaded(true)
      gradebook.setAssignmentGroupsLoaded(true)
      gradebook.setAssignmentsLoaded()
    }

    function waitForTick() {
      return new Promise(resolve => setTimeout(resolve, 0))
    }

    test('does not finish rendering the UI when student ids are not loaded', async () => {
      createInitializedGradebook()
      gradebook.setStudentIdsLoaded(false)
      gradebook._updateEssentialDataLoaded()
      await waitForTick()
      strictEqual(gradebook.finishRenderingUI.callCount, 0)
    })

    test('does not finish rendering the UI when context modules are not loaded', async () => {
      createInitializedGradebook({isModulesLoading: true})
      gradebook._updateEssentialDataLoaded()
      await waitForTick()
      strictEqual(gradebook.finishRenderingUI.callCount, 0)
    })

    test('does not finish rendering the UI when custom columns are not loaded', async () => {
      createInitializedGradebook()
      gradebook._updateEssentialDataLoaded()
      await waitForTick()
      strictEqual(gradebook.finishRenderingUI.callCount, 0)
    })

    test('does not finish rendering the UI when assignment groups are not loaded', async () => {
      createInitializedGradebook()
      gradebook.setAssignmentGroupsLoaded(false)
      gradebook._updateEssentialDataLoaded()
      await waitForTick()
      strictEqual(gradebook.finishRenderingUI.callCount, 0)
    })

    QUnit.module('when the course uses grading periods', contextHooks => {
      contextHooks.beforeEach(() => {
        createInitializedGradebook({
          grading_period_set: {
            grading_periods: [
              {id: '1501', weight: 50},
              {id: '1502', weight: 50},
            ],
            id: '1401',
            weighted: true,
          },
        })
      })

      test('does not finish rendering the UI when grading period assignments are not loaded', async () => {
        gradebook._updateEssentialDataLoaded()
        await waitForTick()
        strictEqual(gradebook.finishRenderingUI.callCount, 0)
      })
    })
  })
})

QUnit.module('Gradebook#renderAssignmentSearchFilter)', {
  setup() {
    setFixtureHtml($fixtures)
    this.gradebook = createGradebook()
    this.gradebook.setStudentsLoaded(true)
    this.gradebook.setSubmissionsLoaded(true)
    this.gradebook.renderAssignmentSearchFilter([])
  },

  teardown() {
    $fixtures.innerHTML = ''
  },
})

test('renders Assignment Names label', function () {
  this.gradebook.renderAssignmentSearchFilter([])
  const assignmentSearch = document.querySelector('#gradebook-assignment-search')
  ok(assignmentSearch.textContent.includes('Assignment Names'))
})

test('enables the input if there is at least one assignment to filter by', function () {
  sinon.stub(this.gradebook.gridReady, 'state').get(() => 'resolved')
  this.gradebook.renderAssignmentSearchFilter([{id: '1', name: 'An Assignment'}])
  const assignmentSearchInput = document.getElementById('assignments-filter')
  notOk(assignmentSearchInput.disabled)
})

test('disables the input if the grid has not yet rendered', function () {
  sinon.stub(this.gradebook.gridReady, 'state').get(() => 'pending')
  this.gradebook.renderAssignmentSearchFilter([{id: '1', name: 'An Assignment'}])
  const assignmentSearchInput = document.getElementById('assignments-filter')
  ok(assignmentSearchInput.disabled)
})

test('disables the input if there are no assignments to filter by', function () {
  sinon.stub(this.gradebook.gridReady, 'state').get(() => 'resolved')
  this.gradebook.renderAssignmentSearchFilter([])
  const assignmentSearchInput = document.getElementById('assignments-filter')
  ok(assignmentSearchInput.disabled)
})

test('displays a select menu option for each assignment', function () {
  sinon.stub(this.gradebook.gridReady, 'state').get(() => 'resolved')
  const assignment = {id: '1', name: 'An assignment'}
  this.gradebook.renderAssignmentSearchFilter([assignment])
  const assignmentSearchInput = document.getElementById('assignments-filter')
  assignmentSearchInput.click()
  const options = [...document.querySelectorAll('ul[role="listbox"] li span[role="option"]')]
  ok(options.some(option => option.textContent === assignment.name))
  assignmentSearchInput.click() // close the menu to avoid DOM test pollution
})

QUnit.module('Gradebook#rowFilter', contextHooks => {
  let gradebook
  let student

  contextHooks.beforeEach(() => {
    student = {
      id: '1',
      login_id: 'charlie.xi@example.com',
      name: 'Charlie Xi',
      short_name: 'Chuck Xi',
      sortable_name: 'Xi, Charlie',
      sis_user_id: '123456789',
    }
  })

  QUnit.module('when gradebook student search', hooks => {
    hooks.beforeEach(() => {
      gradebook = createGradebook()
    })

    test('ignores the userFilterTerm', () => {
      gradebook.userFilterTerm = 'charlie Xi'
      gradebook.filteredStudentIds = ['2']
      strictEqual(gradebook.rowFilter(student), false)
    })

    test('returns true when filtered students include the student', () => {
      gradebook.filteredStudentIds = ['1']
      strictEqual(gradebook.rowFilter(student), true)
    })

    test('returns false when filtered students do not include the student', () => {
      gradebook.filteredStudentIds = ['2']
      strictEqual(gradebook.rowFilter(student), false)
    })

    test('returns true when not filtering students (never filtered)', () => {
      strictEqual(gradebook.rowFilter(student), true)
    })

    test('returns true when not filtering students (originally filtered and then cleared filters)', () => {
      gradebook.filteredStudentIds = []
      strictEqual(gradebook.rowFilter(student), true)
    })
  })
})
