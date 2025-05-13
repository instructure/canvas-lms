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

import {createGradebook, setFixtureHtml} from './GradebookSpecHelper'
import AsyncComponents from '../AsyncComponents'

function gradebookSettingsModalProps() {
  return {
    anonymousSpeedGraderAlertNode: document.createElement('div'),
    colors: {
      dropped: '#FEF0E5',
      excused: '#FEF7E5',
      extended: '#E5F3FC',
      late: '#E5F3FC',
      missing: '#FFE8E5',
      resubmitted: '#E5F3FC',
    },
    courseId: '1',
    courseFeatures: {
      finalGradeOverrideEnabled: false,
      allowViewUngradedAsZero: true,
    },
    locale: 'en',
    gradingSchemeEnabled: true,
    gradingSchemes: [],
    hideAssignmentGroupTotals: false,
    hideTotal: false,
    latePoliciesEnabled: true,
    loadCurrentGradingScheme: () => {},
    loadGradingSchemes: () => {},
    loadLatePolicies: () => {},
    loadStudentSettings: () => {},
    modules: [],
    onClose: () => {},
    saveCurrentGradingScheme: () => {},
    saveGradingScheme: () => {},
    saveLatePolicies: () => {},
    saveSettings: () => {},
    settings: {
      allowViewUngradedAsZero: false,
      showSeparateFirstLastNames: true,
      showUnpublishedAssignments: true,
      statusColors: {
        dropped: '#FEF0E5',
        excused: '#FEF7E5',
        extended: '#E5F3FC',
        late: '#E5F3FC',
        missing: '#FFE8E5',
        resubmitted: '#E5F3FC',
      },
      viewUngradedAsZero: false,
    },
    studentSettings: {
      allowViewUngradedAsZero: false,
      viewUngradedAsZero: false,
    },
  }
}
describe('#renderGradebookSettingsModal', () => {
  let gradebook
  let $fixtures
  let oldEnv
  let renderGradebookSettingsModalMock

  function gradebookSettingsModalProps() {
    return renderGradebookSettingsModalMock.mock.calls[
      renderGradebookSettingsModalMock.mock.calls.length - 1
    ][0]
  }

  beforeEach(() => {
    $fixtures = document.createElement('div')
    document.body.appendChild($fixtures)
    setFixtureHtml($fixtures)
    oldEnv = window.ENV
    window.ENV = {
      FEATURES: {instui_nav: true},
      current_user_id: '1',
      context_id: '1',
    }
    renderGradebookSettingsModalMock = jest.fn()
    AsyncComponents.renderGradebookSettingsModal = renderGradebookSettingsModalMock
  })

  afterEach(() => {
    if (gradebook) {
      gradebook.destroy && gradebook.destroy()
    }
    $fixtures.remove()
    window.ENV = oldEnv
    jest.clearAllMocks()
  })

  test('renders the GradebookSettingsModal component', () => {
    gradebook = createGradebook()
    gradebook.renderGradebookSettingsModal()
    expect(renderGradebookSettingsModalMock).toHaveBeenCalledTimes(1)
  })

  test('sets the .courseFeatures prop to #courseFeatures from Gradebook', () => {
    gradebook = createGradebook()
    gradebook.renderGradebookSettingsModal()
    expect(gradebookSettingsModalProps().courseFeatures).toBe(gradebook.courseFeatures)
  })

  test('sets the .courseSettings prop to #courseSettings from Gradebook', () => {
    gradebook = createGradebook()
    gradebook.renderGradebookSettingsModal()
    expect(gradebookSettingsModalProps().courseSettings).toBe(gradebook.courseSettings)
  })

  test('passes graded_late_submissions_exist option to the modal as a prop', () => {
    gradebook = createGradebook({graded_late_submissions_exist: true})
    gradebook.renderGradebookSettingsModal()
    expect(gradebookSettingsModalProps().gradedLateSubmissionsExist).toBe(true)
  })

  test('passes the context_id option to the modal as a prop', () => {
    gradebook = createGradebook({context_id: '8473'})
    gradebook.renderGradebookSettingsModal()
    expect(gradebookSettingsModalProps().courseId).toBe('8473')
  })

  test('passes the locale option to the modal as a prop', () => {
    gradebook = createGradebook({locale: 'de'})
    gradebook.renderGradebookSettingsModal()
    expect(gradebookSettingsModalProps().locale).toBe('de')
  })

  test('passes the postPolicies object as the prop of the same name', () => {
    gradebook = createGradebook()
    gradebook.renderGradebookSettingsModal()
    expect(gradebookSettingsModalProps().postPolicies).toBe(gradebook.postPolicies)
  })

  describe('.onCourseSettingsUpdated prop', () => {
    let handleUpdatedMock

    beforeEach(() => {
      gradebook = createGradebook()
      handleUpdatedMock = jest.fn()
      gradebook.courseSettings.handleUpdated = handleUpdatedMock
      gradebook.renderGradebookSettingsModal()
      window.ENV = {FEATURES: {instui_nav: true}}
    })

    afterEach(() => {
      window.ENV = oldEnv
    })

    test('updates the course settings when called', () => {
      const settings = {allowFinalGradeOverride: true}
      gradebookSettingsModalProps().onCourseSettingsUpdated(settings)
      expect(handleUpdatedMock).toHaveBeenCalledTimes(1)
    })

    test('updates the course settings using the given course settings data', () => {
      const settings = {allowFinalGradeOverride: true}
      gradebookSettingsModalProps().onCourseSettingsUpdated(settings)
      const [givenSettings] = handleUpdatedMock.mock.calls[0]
      expect(givenSettings).toBe(settings)
    })
  })

  describe('anonymousAssignmentsPresent prop', () => {
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
      window.ENV.SETTINGS = {}
      gradebook = createGradebook()
      gradebook.gotAllAssignmentGroups([anonymousAssignmentGroup, nonAnonymousAssignmentGroup])
      gradebook.renderGradebookSettingsModal()

      expect(gradebookSettingsModalProps().anonymousAssignmentsPresent).toBe(true)
    })

    test('is passed as false if the course has no anonymous assignments', () => {
      window.ENV.SETTINGS = {}
      gradebook = createGradebook()
      gradebook.gotAllAssignmentGroups([nonAnonymousAssignmentGroup])
      gradebook.renderGradebookSettingsModal()

      expect(gradebookSettingsModalProps().anonymousAssignmentsPresent).toBe(false)
    })
  })

  describe('when enhanced gradebook filters are enabled', () => {
    test('sets allowSortingByModules to true if modules are enabled', () => {
      gradebook = createGradebook({enhanced_gradebook_filters: true})
      gradebook.setContextModules([{id: '1', name: 'Module 1', position: 1}])
      gradebook.renderGradebookSettingsModal()

      expect(gradebookSettingsModalProps().allowSortingByModules).toBe(true)
    })

    test('sets allowSortingByModules to false if modules are not enabled', () => {
      gradebook = createGradebook({enhanced_gradebook_filters: true})
      gradebook.renderGradebookSettingsModal()

      expect(gradebookSettingsModalProps().allowSortingByModules).toBe(false)
    })

    test('sets allowViewUngradedAsZero to true if view ungraded as zero is enabled', () => {
      gradebook = createGradebook({
        allow_view_ungraded_as_zero: true,
        enhanced_gradebook_filters: true,
      })
      gradebook.renderGradebookSettingsModal()

      expect(gradebookSettingsModalProps().allowViewUngradedAsZero).toBe(true)
    })

    test('sets allowViewUngradedAsZero to false if view ungraded as zero is not enabled', () => {
      gradebook = createGradebook({enhanced_gradebook_filters: true})
      gradebook.renderGradebookSettingsModal()

      expect(gradebookSettingsModalProps().allowViewUngradedAsZero).toBe(false)
    })

    describe.skip('loadCurrentViewOptions prop', () => {
      const viewOptions = () => gradebookSettingsModalProps().loadCurrentViewOptions()

      test('sets columnSortSettings to the current sort criterion and direction', () => {
        gradebook = createGradebook({enhanced_gradebook_filters: true})
        gradebook.setColumnOrder({sortType: 'due_date', direction: 'descending'})
        gradebook.renderGradebookSettingsModal()

        expect(viewOptions().columnSortSettings).toEqual({
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

        expect(gradebookSettingsModalProps().showNotes).toBe(true)
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

        expect(gradebookSettingsModalProps().showNotes).toBe(false)
      })

      test('sets showNotes to false if the notes column does not exist', () => {
        gradebook = createGradebook({enhanced_gradebook_filters: true})
        gradebook.renderGradebookSettingsModal()
        expect(gradebookSettingsModalProps().showNotes).toBe(false)
      })

      test('sets showUnpublishedAssignments to true if unpublished assignments are shown', () => {
        gradebook = createGradebook({enhanced_gradebook_filters: true})
        gradebook.initShowUnpublishedAssignments('true')
        gradebook.renderGradebookSettingsModal()
        expect(gradebookSettingsModalProps().showUnpublishedAssignments).toBe(true)
      })

      test('sets showUnpublishedAssignments to false if unpublished assignments are not shown', () => {
        gradebook = createGradebook({enhanced_gradebook_filters: true})
        gradebook.initShowUnpublishedAssignments('not true')
        gradebook.renderGradebookSettingsModal()
        expect(gradebookSettingsModalProps().showUnpublishedAssignments).toBe(false)
      })

      test('sets viewUngradedAsZero to true if view ungraded as 0 is active', () => {
        gradebook = createGradebook({
          allow_view_ungraded_as_zero: true,
          enhanced_gradebook_filters: true,
        })
        gradebook.gridDisplaySettings.viewUngradedAsZero = true
        gradebook.renderGradebookSettingsModal()
        expect(gradebookSettingsModalProps().viewUngradedAsZero).toBe(true)
      })

      test('sets viewUngradedAsZero to false if view ungraded as 0 is not active', () => {
        gradebook = createGradebook({
          allow_view_ungraded_as_zero: true,
          enhanced_gradebook_filters: true,
        })
        gradebook.gridDisplaySettings.viewUngradedAsZero = false
        gradebook.renderGradebookSettingsModal()
        expect(gradebookSettingsModalProps().viewUngradedAsZero).toBe(false)
      })
    })
  })
})

describe.skip('when enhanced gradebook filters are not enabled', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
  })

  test('does not set allowSortingByModules', () => {
    gradebook.renderGradebookSettingsModal()
    expect(gradebookSettingsModalProps().allowSortingByModules).toBeUndefined()
  })

  test('does not set allowViewUngradedAsZero', () => {
    gradebook.renderGradebookSettingsModal()
    expect(gradebookSettingsModalProps().allowViewUngradedAsZero).toBeUndefined()
  })

  test('does not set loadCurrentViewOptions', () => {
    gradebook.renderGradebookSettingsModal()
    expect(gradebookSettingsModalProps().loadCurrentViewOptions).toBeUndefined()
  })
})

describe('Gradebook "Enter Grades as" Setting', () => {
  let gradebook
  let updateGridMock

  beforeEach(() => {
    window.ENV = {
      current_user_id: '1',
      context_id: '1',
      GRADEBOOK_OPTIONS: {
        custom_columns: [],
        grading_schemes: [],
        settings_update_url: '/courses/1/gradebook_settings',
      },
      FEATURES: {instui_nav: false},
    }
    gradebook = createGradebook()
    gradebook.setAssignments({
      2301: {
        id: '2301',
        grading_type: 'points',
        name: 'Assignment 1',
        published: true,
        submission_types: ['online_text_entry'],
      },
    })
    updateGridMock = jest.fn()
    gradebook.gradebookGrid.updateColumns = updateGridMock
  })

  afterEach(() => {
    window.ENV = undefined
    jest.clearAllMocks()
  })

  test.skip('calls updateGrid if a corresponding column is found', () => {
    gradebook.postAssignmentGradesTrayOpenChanged({assignmentId: '2301', isOpen: true})
    expect(updateGridMock).toHaveBeenCalledTimes(1)
  })
})
