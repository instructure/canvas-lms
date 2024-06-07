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

import GradebookApi from '../apis/GradebookApi'
import {createGradebook, setFixtureHtml} from './GradebookSpecHelper'
import AsyncComponents from '../AsyncComponents'

const $fixtures = document.getElementById('fixtures')

let oldEnv

QUnit.module('Gradebook#saveSettings', () => {
  let gradebook

  QUnit.module('when enhanced_gradebook_filters is enabled', enhancedFilterHooks => {
    let errorFn
    let successFn
    let saveUserSettingsStub

    enhancedFilterHooks.beforeEach(() => {
      gradebook = createGradebook({
        enhanced_gradebook_filters: true,
      })

      errorFn = sinon.stub()
      successFn = sinon.stub()

      saveUserSettingsStub = sinon.stub(GradebookApi, 'saveUserSettings')

      oldEnv = window.ENV
      window.ENV = {FEATURES: {instui_nav: true}}
    })

    enhancedFilterHooks.afterEach(() => {
      saveUserSettingsStub.restore()
      window.ENV = oldEnv
    })

    test('calls the provided successFn if the request succeeds', async () => {
      saveUserSettingsStub.resolves({})
      await gradebook.saveSettings({}).then(successFn).catch(errorFn)
      strictEqual(successFn.callCount, 1)
      ok(errorFn.notCalled)
    })

    test('calls the provided errorFn if the request fails', async () => {
      saveUserSettingsStub.rejects(new Error(':('))
      await gradebook.saveSettings({}).then(successFn).catch(errorFn)
      strictEqual(errorFn.callCount, 1)
      ok(successFn.notCalled)
    })

    test('just returns if the request succeeds and no successFn is provided', async () => {
      QUnit.expect(0)
      saveUserSettingsStub.resolves({})
      await gradebook.saveSettings({})
    })

    test('throws an error if the request fails and no errorFn is provided', async () => {
      QUnit.expect(1)
      saveUserSettingsStub.rejects(new Error('>:('))

      try {
        await gradebook.saveSettings({})
      } catch (error) {
        strictEqual(error.message, '>:(')
      }
    })
  })
})

QUnit.module('#renderGradebookSettingsModal', hooks => {
  let gradebook

  function gradebookSettingsModalProps() {
    return AsyncComponents.renderGradebookSettingsModal.lastCall.args[0]
  }

  hooks.beforeEach(() => {
    setFixtureHtml($fixtures)
    sandbox.stub(AsyncComponents, 'renderGradebookSettingsModal')
    oldEnv = window.ENV
    window.ENV = {FEATURES: {instui_nav: true}}
  })

  hooks.afterEach(() => {
    $fixtures.innerHTML = ''
    window.ENV = oldEnv
  })

  test('renders the GradebookSettingsModal component', () => {
    gradebook = createGradebook()
    gradebook.renderGradebookSettingsModal()
    strictEqual(AsyncComponents.renderGradebookSettingsModal.callCount, 1)
  })

  test('sets the .courseFeatures prop to #courseFeatures from Gradebook', () => {
    gradebook = createGradebook()
    gradebook.renderGradebookSettingsModal()
    strictEqual(gradebookSettingsModalProps().courseFeatures, gradebook.courseFeatures)
  })

  test('sets the .courseSettings prop to #courseSettings from Gradebook', () => {
    gradebook = createGradebook()
    gradebook.renderGradebookSettingsModal()
    strictEqual(gradebookSettingsModalProps().courseSettings, gradebook.courseSettings)
  })

  test('passes graded_late_submissions_exist option to the modal as a prop', () => {
    gradebook = createGradebook({graded_late_submissions_exist: true})
    gradebook.renderGradebookSettingsModal()
    strictEqual(gradebookSettingsModalProps().gradedLateSubmissionsExist, true)
  })

  test('passes the context_id option to the modal as a prop', () => {
    gradebook = createGradebook({context_id: '8473'})
    gradebook.renderGradebookSettingsModal()
    strictEqual(gradebookSettingsModalProps().courseId, '8473')
  })

  test('passes the locale option to the modal as a prop', () => {
    gradebook = createGradebook({locale: 'de'})
    gradebook.renderGradebookSettingsModal()
    strictEqual(gradebookSettingsModalProps().locale, 'de')
  })

  test('passes the postPolicies object as the prop of the same name', () => {
    gradebook = createGradebook()
    gradebook.renderGradebookSettingsModal()
    strictEqual(gradebookSettingsModalProps().postPolicies, gradebook.postPolicies)
  })

  QUnit.module('.onCourseSettingsUpdated prop', propHooks => {
    propHooks.beforeEach(() => {
      gradebook = createGradebook()
      gradebook.renderGradebookSettingsModal()
      sinon.stub(gradebook.courseSettings, 'handleUpdated')
      oldEnv = window.ENV
      window.ENV = {FEATURES: {instui_nav: true}}
    })

    propHooks.afterEach(() => {
      window.ENV = oldEnv
    })

    test('updates the course settings when called', () => {
      const settings = {allowFinalGradeOverride: true}
      gradebookSettingsModalProps().onCourseSettingsUpdated(settings)
      strictEqual(gradebook.courseSettings.handleUpdated.callCount, 1)
    })

    test('updates the course settings using the given course settings data', () => {
      const settings = {allowFinalGradeOverride: true}
      gradebookSettingsModalProps().onCourseSettingsUpdated(settings)
      const [givenSettings] = gradebook.courseSettings.handleUpdated.lastCall.args
      strictEqual(givenSettings, settings)
    })
  })

  QUnit.module('anonymousAssignmentsPresent prop', () => {
    const anonymousAssignmentGroup = {
      assignments: [
        {
          anonymous_grading: true,
          assignment_group_id: '10001',
          id: '101',
          name: 'Anonymous',
          points_possible: 10,
          published: true,
        },
      ],
      group_weight: 1,
      id: '10001',
      name: 'An anonymous assignment group',
    }

    const nonAnonymousAssignmentGroup = {
      assignments: [
        {
          anonymous_grading: false,
          assignment_group_id: '10002',
          id: '102',
          name: 'Not-Anonymous',
          points_possible: 10,
          published: true,
        },
      ],
      group_weight: 1,
      id: '10002',
      name: 'An anonymous assignment group',
    }

    test('is passed as true if the course has at least one anonymous assignment', () => {
      gradebook = createGradebook()
      gradebook.gotAllAssignmentGroups([anonymousAssignmentGroup, nonAnonymousAssignmentGroup])
      gradebook.renderGradebookSettingsModal()

      strictEqual(gradebookSettingsModalProps().anonymousAssignmentsPresent, true)
    })

    test('is passed as false if the course has no anonymous assignments', () => {
      gradebook = createGradebook()
      gradebook.gotAllAssignmentGroups([nonAnonymousAssignmentGroup])
      gradebook.renderGradebookSettingsModal()

      strictEqual(gradebookSettingsModalProps().anonymousAssignmentsPresent, false)
    })
  })

  QUnit.module('when enhanced gradebook filters are enabled', () => {
    test('sets allowSortingByModules to true if modules are enabled', () => {
      gradebook = createGradebook({enhanced_gradebook_filters: true})
      gradebook.setContextModules([{id: '1', name: 'Module 1', position: 1}])
      gradebook.renderGradebookSettingsModal()

      strictEqual(gradebookSettingsModalProps().allowSortingByModules, true)
    })

    test('sets allowSortingByModules to false if modules are not enabled', () => {
      gradebook = createGradebook({enhanced_gradebook_filters: true})
      gradebook.renderGradebookSettingsModal()

      strictEqual(gradebookSettingsModalProps().allowSortingByModules, false)
    })

    test('sets allowViewUngradedAsZero to true if view ungraded as zero is enabled', () => {
      gradebook = createGradebook({
        allow_view_ungraded_as_zero: true,
        enhanced_gradebook_filters: true,
      })
      gradebook.renderGradebookSettingsModal()

      strictEqual(gradebookSettingsModalProps().allowViewUngradedAsZero, true)
    })

    test('sets allowViewUngradedAsZero to false if view ungraded as zero is not enabled', () => {
      gradebook = createGradebook({enhanced_gradebook_filters: true})
      gradebook.renderGradebookSettingsModal()

      strictEqual(gradebookSettingsModalProps().allowViewUngradedAsZero, false)
    })

    QUnit.module('loadCurrentViewOptions prop', () => {
      const viewOptions = () => gradebookSettingsModalProps().loadCurrentViewOptions()

      test('sets columnSortSettings to the current sort criterion and direction', () => {
        gradebook = createGradebook({enhanced_gradebook_filters: true})
        gradebook.setColumnOrder({sortType: 'due_date', direction: 'descending'})
        gradebook.renderGradebookSettingsModal()

        deepEqual(viewOptions().columnSortSettings, {
          criterion: 'due_date',
          direction: 'descending',
        })
      })

      test('sets showNotes to true if the notes column is shown', () => {
        gradebook = createGradebook({
          enhanced_gradebook_filters: true,
          teacher_notes: {
            id: '2401',
            title: 'Notes',
            position: 1,
            teacher_notes: true,
            hidden: false,
          },
        })
        gradebook.renderGradebookSettingsModal()

        strictEqual(viewOptions().showNotes, true)
      })

      test('sets showNotes to false if the notes column is hidden', () => {
        gradebook = createGradebook({
          enhanced_gradebook_filters: true,
          teacher_notes: {
            id: '2401',
            title: 'Notes',
            position: 1,
            teacher_notes: true,
            hidden: true,
          },
        })
        gradebook.renderGradebookSettingsModal()

        strictEqual(viewOptions().showNotes, false)
      })

      test('sets showNotes to false if the notes column does not exist', () => {
        gradebook = createGradebook({enhanced_gradebook_filters: true})
        gradebook.renderGradebookSettingsModal()
        strictEqual(viewOptions().showNotes, false)
      })

      test('sets showUnpublishedAssignments to true if unpublished assignments are shown', () => {
        gradebook = createGradebook({enhanced_gradebook_filters: true})
        gradebook.initShowUnpublishedAssignments('true')
        gradebook.renderGradebookSettingsModal()
        strictEqual(viewOptions().showUnpublishedAssignments, true)
      })

      test('sets showUnpublishedAssignments to false if unpublished assignments are not shown', () => {
        gradebook = createGradebook({enhanced_gradebook_filters: true})
        gradebook.initShowUnpublishedAssignments('not true')
        gradebook.renderGradebookSettingsModal()
        strictEqual(viewOptions().showUnpublishedAssignments, false)
      })

      test('sets viewUngradedAsZero to true if view ungraded as 0 is active', () => {
        gradebook = createGradebook({
          allow_view_ungraded_as_zero: true,
          enhanced_gradebook_filters: true,
        })
        gradebook.gridDisplaySettings.viewUngradedAsZero = true
        gradebook.renderGradebookSettingsModal()
        strictEqual(viewOptions().viewUngradedAsZero, true)
      })

      test('sets viewUngradedAsZero to true if view ungraded as 0 is not active', () => {
        gradebook = createGradebook({
          allow_view_ungraded_as_zero: true,
          enhanced_gradebook_filters: true,
        })
        gradebook.gridDisplaySettings.viewUngradedAsZero = false
        gradebook.renderGradebookSettingsModal()
        strictEqual(viewOptions().viewUngradedAsZero, false)
      })
    })
  })

  QUnit.module('when enhanced gradebook filters are not enabled', () => {
    test('does not set allowSortingByModules', () => {
      gradebook = createGradebook()
      gradebook.renderGradebookSettingsModal()
      strictEqual(gradebookSettingsModalProps().allowSortingByModules, undefined)
    })

    test('does not set allowViewUngradedAsZero', () => {
      gradebook = createGradebook()
      gradebook.renderGradebookSettingsModal()
      strictEqual(gradebookSettingsModalProps().allowViewUngradedAsZero, undefined)
    })

    test('does not set loadCurrentViewOptions', () => {
      gradebook = createGradebook()
      gradebook.renderGradebookSettingsModal()
      strictEqual(gradebookSettingsModalProps().loadCurrentViewOptions, undefined)
    })
  })
})

QUnit.module('Gradebook "Enter Grades as" Setting', suiteHooks => {
  let server
  let options
  let gradebook

  suiteHooks.beforeEach(() => {
    options = {settings_update_url: '/course/1/gradebook_settings'}
    server = sinon.fakeServer.create({respondImmediately: true})
    server.respondWith('POST', options.settings_update_url, [
      200,
      {'Content-Type': 'application/json'},
      '{}',
    ])
    gradebook = createGradebook(options)
    gradebook.setAssignments({
      2301: {id: '2301', grading_type: 'points', name: 'Math Assignment', published: true},
      2302: {id: '2302', grading_type: 'points', name: 'English Assignment', published: false},
    })
    gradebook.gradebookGrid.grid = {
      invalidate() {},
    }
    gradebook.gradebookGrid.gridSupport = {
      columns: {
        updateColumnHeaders() {},
      },
    }
    oldEnv = window.ENV
    window.ENV = {FEATURES: {instui_nav: false}}
  })

  suiteHooks.afterEach(() => {
    server.restore()
    window.ENV = oldEnv
  })

  QUnit.module('#getEnterGradesAsSetting', () => {
    test('returns the setting when stored', () => {
      gradebook.setEnterGradesAsSetting('2301', 'percent')
      equal(gradebook.getEnterGradesAsSetting('2301'), 'percent')
    })

    test('defaults to "points" for a "points" assignment', () => {
      gradebook.getAssignment('2301').grading_type = 'points'
      equal(gradebook.getEnterGradesAsSetting('2301'), 'points')
    })

    test('defaults to "percent" for a "percent" assignment', () => {
      gradebook.getAssignment('2301').grading_type = 'percent'
      equal(gradebook.getEnterGradesAsSetting('2301'), 'percent')
    })

    test('defaults to "passFail" for a "pass_fail" assignment', () => {
      gradebook.getAssignment('2301').grading_type = 'pass_fail'
      equal(gradebook.getEnterGradesAsSetting('2301'), 'passFail')
    })

    test('defaults to "gradingScheme" for a "letter_grade" assignment', () => {
      gradebook.getAssignment('2301').grading_type = 'letter_grade'
      equal(gradebook.getEnterGradesAsSetting('2301'), 'gradingScheme')
    })

    test('defaults to "gradingScheme" for a "gpa_scale" assignment', () => {
      gradebook.getAssignment('2301').grading_type = 'gpa_scale'
      equal(gradebook.getEnterGradesAsSetting('2301'), 'gradingScheme')
    })

    test('defaults to null for a "not_graded" assignment', () => {
      gradebook.getAssignment('2301').grading_type = 'not_graded'
      strictEqual(gradebook.getEnterGradesAsSetting('2301'), null)
    })

    test('defaults to null for a "not_graded" assignment previously set as "points"', () => {
      gradebook.updateEnterGradesAsSetting('2301', 'points')
      gradebook.getAssignment('2301').grading_type = 'not_graded'
      strictEqual(gradebook.getEnterGradesAsSetting('2301'), null)
    })

    test('defaults to null for a "not_graded" assignment previously set as "percent"', () => {
      gradebook.updateEnterGradesAsSetting('2301', 'percent')
      gradebook.getAssignment('2301').grading_type = 'not_graded'
      strictEqual(gradebook.getEnterGradesAsSetting('2301'), null)
    })

    test('defaults to "points" for a "points" assignment previously set as "gradingScheme"', () => {
      gradebook.updateEnterGradesAsSetting('2301', 'gradingScheme')
      gradebook.getAssignment('2301').grading_type = 'points'
      equal(gradebook.getEnterGradesAsSetting('2301'), 'points')
    })

    test('defaults to "percent" for a "percent" assignment previously set as "gradingScheme"', () => {
      gradebook.updateEnterGradesAsSetting('2301', 'gradingScheme')
      gradebook.getAssignment('2301').grading_type = 'percent'
      equal(gradebook.getEnterGradesAsSetting('2301'), 'percent')
    })
  })

  QUnit.module('#updateEnterGradesAsSetting', hooks => {
    hooks.beforeEach(() => {
      sinon.stub(gradebook, 'saveSettings').callsFake(() => Promise.resolve())
      sinon.stub(gradebook.gradebookGrid, 'invalidate')
      sinon.stub(gradebook.gradebookGrid.gridSupport.columns, 'updateColumnHeaders')
      oldEnv = window.ENV
      window.ENV = {FEATURES: {instui_nav: false}}
    })

    hooks.afterEach(() => {
      gradebook.saveSettings.restore()
      window.ENV = oldEnv
    })

    test('updates the setting in Gradebook', () => {
      gradebook.updateEnterGradesAsSetting('2301', 'percent')
      equal(gradebook.getEnterGradesAsSetting('2301'), 'percent')
    })

    test('saves gradebooks settings', () => {
      gradebook.updateEnterGradesAsSetting('2301', 'percent')
      strictEqual(gradebook.saveSettings.callCount, 1)
    })

    test('saves gradebooks settings after updating the "enter grades as" setting', async () => {
      await gradebook.updateEnterGradesAsSetting('2301', 'percent')
      equal(gradebook.getEnterGradesAsSetting('2301'), 'percent')
    })

    test('updates the column header for the related assignment column', async () => {
      await gradebook.updateEnterGradesAsSetting('2301', 'percent')
      strictEqual(gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.callCount, 1)
    })

    test('updates the column header with the assignment column id', async () => {
      await gradebook.updateEnterGradesAsSetting('2301', 'percent')
      const [columnIds] =
        gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.lastCall.args
      deepEqual(columnIds, ['assignment_2301'])
    })

    test('updates the column header after settings have been saved', async () => {
      strictEqual(gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.callCount, 0)
      gradebook.updateEnterGradesAsSetting('2301', 'percent')
      await gradebook.saveSettings.callsFake(() => {
        return Promise.resolve()
      })
      strictEqual(gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.callCount, 1)
    })

    test('invalidates the grid', async () => {
      await gradebook.updateEnterGradesAsSetting('2301', 'percent')
      strictEqual(gradebook.gradebookGrid.invalidate.callCount, 1)
    })

    test('invalidates the grid after updating the column header', () => {
      gradebook.gradebookGrid.invalidate.callsFake(() => {
        strictEqual(gradebook.gradebookGrid.invalidate.callCount, 1)
      })
      gradebook.updateEnterGradesAsSetting('2301', 'percent')
    })
  })

  QUnit.module('#postAssignmentGradesTrayOpenChanged', hooks => {
    let updateGridStub

    hooks.beforeEach(() => {
      const assignment = {id: '2301'}
      const column = gradebook.buildAssignmentColumn(assignment)
      gradebook.gridData.columns.definitions[column.id] = column
      updateGridStub = sinon.stub(gradebook, 'updateGrid')
      oldEnv = window.ENV
      window.ENV = {FEATURES: {instui_nav: false}}
    })

    hooks.afterEach(() => {
      updateGridStub.restore()
      window.ENV = oldEnv
    })

    test('calls updateGrid if a corresponding column is found', () => {
      gradebook.postAssignmentGradesTrayOpenChanged({assignmentId: '2301', isOpen: true})
      strictEqual(updateGridStub.callCount, 1)
    })

    test('does not call updateGrid if a corresponding column is not found', () => {
      gradebook.postAssignmentGradesTrayOpenChanged({assignmentId: '2399', isOpen: true})
      strictEqual(updateGridStub.callCount, 0)
    })
  })
})
