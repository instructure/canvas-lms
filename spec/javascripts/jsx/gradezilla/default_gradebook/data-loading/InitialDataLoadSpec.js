/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import DataLoader from 'jsx/gradezilla/DataLoader'
import {createGradebook, setFixtureHtml} from 'jsx/gradezilla/default_gradebook/__tests__/GradebookSpecHelper'
import {createExampleStudents} from './DataLoadingSpecHelpers'
import DataLoadingWrapper from './DataLoadingWrapper'

QUnit.module('Gradebook Initial Data Loading', suiteHooks => {
  let $container
  let dataLoadingWrapper
  let gradebook
  let gradebookOptions

  let initialData

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
    setFixtureHtml($container)

    initialData = {
      contextModules: [
        {id: '2601', position: 3, name: 'English'},
        {id: '2602', position: 1, name: 'Math'},
        {id: '2603', position: 2, name: 'Science'}
      ],
      gradingPeriodAssignments: {
        1401: ['2301', '2303'],
        1402: ['2302', '2304']
      },
      studentIds: ['1101', '1102', '1103', '1104'],
      students: createExampleStudents()
    }

    gradebookOptions = {
      api_max_per_page: 50,
      assignment_groups_url: '/assignment-groups',
      chunk_size: 10,
      context_id: '1201',
      context_modules_url: '/context-modules',
      custom_column_data_url: '/custom-column-data',
      final_grade_override_enabled: false,
      sections: [{id: '2001', name: 'Freshmen'}, {id: '2002', name: 'Sophomores'}],
      students_stateless_url: '/students-url',
      submissions_url: '/submissions-url'
    }

    dataLoadingWrapper = new DataLoadingWrapper()
    dataLoadingWrapper.setup()
  })

  suiteHooks.afterEach(() => {
    gradebook.destroy()
    $container.remove()
    dataLoadingWrapper.teardown()
  })

  function initializeGradebook(options = {}) {
    if (options.includeGradingPeriodSet) {
      gradebookOptions.grading_period_set = {
        grading_periods: [
          {id: '1401', startDate: new Date('2015-09-01'), title: 'Q1'},
          {id: '1402', startDate: new Date('2015-10-15'), title: 'Q2'}
        ],
        id: '1301'
      }
    }

    gradebook = createGradebook(gradebookOptions)
    sinon.stub(gradebook, 'saveSettings').callsFake((settings, onSuccess = () => {}) => {
      onSuccess(settings)
    })

    gradebook.initialize()
  }

  QUnit.module('when Gradebook initializes', () => {
    test('sets the students as not loaded', () => {
      initializeGradebook()
      strictEqual(gradebook.contentLoadStates.studentsLoaded, false)
    })

    test('sets the submissions as not loaded', () => {
      initializeGradebook()
      strictEqual(gradebook.contentLoadStates.submissionsLoaded, false)
    })

    test('calls DataLoader.loadGradebookData()', () => {
      initializeGradebook()
      strictEqual(DataLoader.loadGradebookData.callCount, 1)
    })

    test('includes the course id when calling DataLoader.loadGradebookData()', () => {
      initializeGradebook()
      const [options] = DataLoader.loadGradebookData.lastCall.args
      equal(options.courseId, '1201')
    })

    test('includes the gradebook when calling DataLoader.loadGradebookData()', () => {
      initializeGradebook()
      const [options] = DataLoader.loadGradebookData.lastCall.args
      strictEqual(options.gradebook, gradebook)
    })

    test('includes the per page api request setting when calling DataLoader.loadGradebookData()', () => {
      initializeGradebook()
      const [options] = DataLoader.loadGradebookData.lastCall.args
      equal(options.perPage, 50)
    })

    test('requests assignment groups', () => {
      initializeGradebook()
      const [options] = DataLoader.loadGradebookData.lastCall.args
      equal(options.assignmentGroupsURL, '/assignment-groups')
    })

    test('requests context modules', () => {
      initializeGradebook()
      const [options] = DataLoader.loadGradebookData.lastCall.args
      equal(options.contextModulesURL, '/context-modules')
    })

    test('requests data for hidden custom columns', () => {
      initializeGradebook()
      const [options] = DataLoader.loadGradebookData.lastCall.args
      strictEqual(options.customColumnDataParams.include_hidden, true)
    })

    test('requests final grade overrides when the feature is enabled', () => {
      gradebookOptions.final_grade_override_enabled = true
      initializeGradebook()
      const [options] = DataLoader.loadGradebookData.lastCall.args
      strictEqual(options.getFinalGradeOverrides, true)
    })

    test('does not request final grade overrides when the feature is not enabled', () => {
      gradebookOptions.final_grade_override_enabled = false
      initializeGradebook()
      const [options] = DataLoader.loadGradebookData.lastCall.args
      strictEqual(options.getFinalGradeOverrides, false)
    })
  })

  QUnit.module('when student ids finish loading', contextHooks => {
    contextHooks.beforeEach(() => {
      initializeGradebook()
    })

    test('stores the loaded student ids in the Gradebook', () => {
      dataLoadingWrapper.loadStudentIds(initialData.studentIds)
      deepEqual(gradebook.courseContent.students.listStudentIds(), initialData.studentIds)
    })
  })

  QUnit.module('when context modules finish loading', contextHooks => {
    contextHooks.beforeEach(() => {
      initializeGradebook()
    })

    test('stores the loaded context modules in the Gradebook', () => {
      dataLoadingWrapper.loadContextModules(initialData.contextModules)
      deepEqual(gradebook.listContextModules(), initialData.contextModules)
    })

    test('sets context modules as loaded', () => {
      dataLoadingWrapper.loadContextModules(initialData.contextModules)
      strictEqual(gradebook.contentLoadStates.contextModulesLoaded, true)
    })

    test('re-renders the view options menu after storing the loaded context modules', () => {
      sinon.stub(gradebook, 'renderViewOptionsMenu').callsFake(() => {
        equal(gradebook.listContextModules(), initialData.contextModules)
      })
      dataLoadingWrapper.loadContextModules(initialData.contextModules)
    })
  })

  QUnit.module('when essential grid data finishes loading', () => {
    function loadEssentialGridData() {
      dataLoadingWrapper.loadAssignmentGroups([])
      dataLoadingWrapper.loadContextModules([])
      dataLoadingWrapper.loadCustomColumns()
      dataLoadingWrapper.loadStudentIds(initialData.studentIds)
    }

    test('adds grid rows for the loaded student ids', () => {
      initializeGradebook()
      loadEssentialGridData()
      strictEqual(document.body.querySelectorAll('.canvas_0 .slick-row').length, 4)
    })

    test('renders the StatusesModal', () => {
      initializeGradebook()
      sinon.spy(gradebook, 'renderStatusesModal')
      loadEssentialGridData()
      strictEqual(gradebook.renderStatusesModal.callCount, 1)
    })
  })

  QUnit.module('loading students', hooks => {
    hooks.beforeEach(() => {
      initializeGradebook()
      dataLoadingWrapper.loadStudentIds(initialData.studentIds)
      dataLoadingWrapper.loadAssignmentGroups([])
      dataLoadingWrapper.loadContextModules([])
      dataLoadingWrapper.loadCustomColumns()
    })

    QUnit.module('when a chunk of students have loaded', () => {
      test('adds the loaded students to the Gradebook', () => {
        dataLoadingWrapper.loadStudents(initialData.students)
        const studentNames = gradebook.courseContent.students
          .listStudents()
          .map(student => student.name)
        deepEqual(studentNames.sort(), ['Adam Jones', 'Betty Ford', 'Charlie Xi', 'Dana Young'])
      })

      test('updates the rows for loaded students', () => {
        dataLoadingWrapper.loadStudents(initialData.students)
        const $studentNames = document.body.querySelectorAll('.slick-row .student-name')
        const studentNames = [...$studentNames].map($name => $name.textContent.trim())
        deepEqual(studentNames, ['Adam Jones', 'Betty Ford', 'Charlie Xi', 'Dana Young'])
      })
    })

    QUnit.module('when students finish loading', contextHooks => {
      contextHooks.beforeEach(() => {
        dataLoadingWrapper.loadStudents(initialData.students)
      })

      test('sets the students as loaded', () => {
        dataLoadingWrapper.finishLoadingStudents()
        strictEqual(gradebook.contentLoadStates.studentsLoaded, true)
      })

      test('re-renders the column headers', () => {
        sinon.spy(gradebook, 'updateColumnHeaders')
        dataLoadingWrapper.finishLoadingStudents()
        strictEqual(gradebook.updateColumnHeaders.callCount, 1)
      })

      test('re-renders the column headers after setting students as loaded', () => {
        sinon.stub(gradebook, 'updateColumnHeaders').callsFake(() => {
          // students load state was already updated
          strictEqual(gradebook.contentLoadStates.studentsLoaded, true)
        })
        dataLoadingWrapper.finishLoadingStudents()
      })

      test('re-renders the filters', () => {
        sinon.spy(gradebook, 'renderFilters')
        dataLoadingWrapper.finishLoadingStudents()
        strictEqual(gradebook.renderFilters.callCount, 1)
      })

      test('re-renders the filters after setting students as loaded', () => {
        sinon.stub(gradebook, 'renderFilters').callsFake(() => {
          // students load state was already updated
          strictEqual(gradebook.contentLoadStates.studentsLoaded, true)
        })
        dataLoadingWrapper.finishLoadingStudents()
      })
    })
  })

  QUnit.module('loading submissions', hooks => {
    hooks.beforeEach(() => {
      initializeGradebook()
    })

    QUnit.module('when submissions finish loading', () => {
      test('updates submissions load state when loaded', () => {
        dataLoadingWrapper.finishLoadingSubmissions()
        strictEqual(gradebook.contentLoadStates.submissionsLoaded, true)
      })

      test('re-renders the column headers', () => {
        sandbox.spy(gradebook, 'updateColumnHeaders')
        dataLoadingWrapper.finishLoadingSubmissions()
        strictEqual(gradebook.updateColumnHeaders.callCount, 1)
      })

      test('re-renders the column headers after setting submissions as loaded', () => {
        sandbox.stub(gradebook, 'updateColumnHeaders').callsFake(() => {
          // submissions load state was already updated
          strictEqual(gradebook.contentLoadStates.submissionsLoaded, true)
        })
        dataLoadingWrapper.finishLoadingSubmissions()
      })

      test('re-renders the filters', () => {
        sandbox.spy(gradebook, 'renderFilters')
        dataLoadingWrapper.finishLoadingSubmissions()
        strictEqual(gradebook.renderFilters.callCount, 1)
      })

      test('re-renders the filters after setting submissions as loaded', () => {
        sandbox.stub(gradebook, 'renderFilters').callsFake(() => {
          // submissions load state was already updated
          strictEqual(gradebook.contentLoadStates.submissionsLoaded, true)
        })
        dataLoadingWrapper.finishLoadingSubmissions()
      })
    })
  })
})
