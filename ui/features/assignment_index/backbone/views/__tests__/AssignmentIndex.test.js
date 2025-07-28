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

import AssignmentGroup from '@canvas/assignments/backbone/models/AssignmentGroup'
import Course from '@canvas/courses/backbone/models/Course'
import AssignmentGroupCollection from '@canvas/assignments/backbone/collections/AssignmentGroupCollection'
import AssignmentGroupListView from '../AssignmentGroupListView'
import AssignmentSettingsView from '../AssignmentSettingsView'
import AssignmentSyncSettingsView from '../AssignmentSyncSettingsView'
import AssignmentGroupWeightsView from '../AssignmentGroupWeightsView'
import IndexView from '../IndexView'
import ToggleShowByView from '../ToggleShowByView'
import $ from 'jquery'
import 'jquery-migrate'
import fakeENV from '@canvas/test-utils/fakeENV'
import '@testing-library/jest-dom'

let assignmentGroups = null
let container = null

const createAssignmentIndex = (opts = {withAssignmentSettings: false}) => {
  container = document.createElement('div')
  container.id = 'content'
  document.body.appendChild(container)

  const course = new Course({id: 1})

  const group1 = new AssignmentGroup({
    name: 'Group 1',
    assignments: [
      {id: 1, name: 'Foo Name'},
      {id: 2, name: 'Bar Title'},
    ],
  })
  const group2 = new AssignmentGroup({
    name: 'Group 2',
    assignments: [
      {id: 1, name: 'Baz Title'},
      {id: 2, name: 'Qux Name'},
    ],
  })
  assignmentGroups = new AssignmentGroupCollection([group1, group2], {course})

  let assignmentSettingsView = false
  let assignmentSyncSettingsView = false
  if (opts.withAssignmentSettings) {
    assignmentSettingsView = new AssignmentSettingsView({
      model: course,
      assignmentGroups,
      weightsView: AssignmentGroupWeightsView,
      userIsAdmin: true,
    })
  }
  assignmentSyncSettingsView = new AssignmentSyncSettingsView({
    collection: assignmentGroups,
    model: course,
    sisName: 'ENV.SIS_NAME',
  })

  const assignmentGroupsView = new AssignmentGroupListView({
    collection: assignmentGroups,
    course,
  })

  let showByView = false
  if (!ENV.PERMISSIONS.manage) {
    showByView = new ToggleShowByView({
      course,
      assignmentGroups,
    })
  }

  const app = new IndexView({
    assignmentGroupsView,
    collection: assignmentGroups,
    createGroupView: false,
    assignmentSettingsView,
    assignmentSyncSettingsView,
    showByView,
    ...opts,
  })

  return app.render()
}

describe('AssignmentIndex', () => {
  beforeEach(() => {
    fakeENV.setup({
      URLS: {
        assignment_sort_base_url: 'test',
      },
      QUIZ_LTI_ENABLED: false,
      FEATURES: {
        instui_nav: true,
      },
      PERMISSIONS: {
        manage_assignments_add: true,
      },
      SETTINGS: {},
    })
  })

  afterEach(() => {
    fakeENV.teardown()
    assignmentGroups = null
    container?.remove()
    container = null
  })

  it('should filter by search term', () => {
    const view = createAssignmentIndex()
    $('#search_term').val('foo')
    view.filterResults()
    expect(view.$el.find('.assignment').not('.hidden')).toHaveLength(1)

    $('#search_term').val('BooBerry')
    view.filterResults()
    expect(view.$el.find('.assignment').not('.hidden')).toHaveLength(0)

    $('#search_term').val('name')
    view.filterResults()
    expect(view.$el.find('.assignment').not('.hidden')).toHaveLength(2)
  })

  it('should have search disabled on render', () => {
    const view = createAssignmentIndex()
    expect(view.$('#search_term').is(':disabled')).toBe(true)
  })

  it('should enable search on assignmentGroup reset', () => {
    const view = createAssignmentIndex()
    assignmentGroups.reset()
    expect(view.$('#search_term').is(':disabled')).toBe(false)
  })

  it('enable search handler should only fire on the first reset', () => {
    const enableSearchSpy = jest.spyOn(IndexView.prototype, 'enableSearch')
    createAssignmentIndex()
    assignmentGroups.reset()
    expect(enableSearchSpy).toHaveBeenCalledTimes(1)
    assignmentGroups.reset()
    expect(enableSearchSpy).toHaveBeenCalledTimes(1)
    enableSearchSpy.mockRestore()
  })

  it('should show modules column correctly', () => {
    fakeENV.setup({
      PERMISSIONS: {manage: true},
      URLS: {
        assignment_sort_base_url: 'test',
      },
      SETTINGS: {},
    })

    const view = createAssignmentIndex()
    const assignments = assignmentGroups.assignments()

    // Assignment with multiple modules
    assignments[0].set({
      id: 1,
      labelId: 'assign1',
      modules: ['Module One', 'Module Two'],
      has_modules: true,
      module_count: 2,
      joined_names: 'Module One, Module Two',
    })

    // Assignment with one module
    assignments[1].set({
      id: 2,
      labelId: 'assign2',
      modules: ['Single Module'],
      has_modules: true,
      module_count: 1,
      module_name: 'Single Module',
    })

    // Assignment with no modules
    assignments[2].set({
      id: 3,
      labelId: 'assign3',
      modules: [],
      has_modules: false,
      module_count: 0,
      joined_names: '',
    })

    view.render()

    // Check multiple modules
    const $firstRow = view.$('#assignment_1')
    const $firstModules = $firstRow.find('.ig-details__item--wrap-text.modules')
    expect($firstModules).toHaveLength(1)
    expect($firstModules.find('a').attr('title')).toBe('Module One,Module Two')

    // Check single module
    const $secondRow = view.$('#assignment_2')
    const $secondModules = $secondRow.find('.ig-details__item--wrap-text.modules')
    expect($secondModules).toHaveLength(1)
    expect($secondModules.text().trim().replace(/\s+/g, ' ')).toBe(
      'Single Module Module Single Module',
    )

    // Check no modules
    const $thirdRow = view.$('#assignment_3')
    expect($thirdRow.find('.ig-details__item--wrap-text.modules')).toHaveLength(0)

    fakeENV.teardown()
  })

  it("should show 'Add Quiz/Test' button if quiz lti is enabled", () => {
    ENV.QUIZ_LTI_ENABLED = true
    ENV.FEATURES.instui_nav = false
    const view = createAssignmentIndex({withAssignmentSettings: true})
    const $button = view.$('.new_quiz_lti')
    expect($button).toHaveLength(1)
    expect($button.attr('href')).toMatch(/\?quiz_lti$/)
  })

  it("should not show 'Add Quiz/Test' button if quiz lti is not enabled", () => {
    ENV.QUIZ_LTI_ENABLED = false
    const view = createAssignmentIndex({withAssignmentSettings: true})
    expect(view.$('#new_quiz_lti')).toHaveLength(0)
  })
})
