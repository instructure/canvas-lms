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

import Backbone from '@canvas/backbone'
import AssignmentGroupCollection from '@canvas/assignments/backbone/collections/AssignmentGroupCollection'
import AssignmentGroupListItemView from '../AssignmentGroupListItemView'
import $ from 'jquery'
import 'jquery-migrate'

const buildAssignment = (options = {}) => {
  const base = {
    assignment_group_id: 1,
    due_at: null,
    grading_type: 'points',
    points_possible: 5,
    position: 2,
    course_id: 1,
    name: 'Science Quiz',
    submission_types: [],
    html_url: `http://localhost:3000/courses/1/assignments/${options.id}`,
    needs_grading_count: 0,
    all_dates: [],
    published: true,
  }
  return {...base, ...options}
}

const assignment1 = () => {
  const date1 = {
    due_at: '2013-08-28T23:59:00-06:00',
    title: 'Summer Session',
  }
  const date2 = {
    due_at: '2013-08-28T23:59:00-06:00',
    title: 'Winter Session',
  }

  return buildAssignment({
    id: 1,
    name: 'History Quiz',
    description: 'test',
    due_at: '2013-08-21T23:59:00-06:00',
    points_possible: 2,
    position: 1,
    all_dates: [date1, date2],
  })
}

const assignment2 = () =>
  buildAssignment({
    id: 3,
    name: 'Math Quiz',
    due_at: '2013-08-23T23:59:00-06:00',
    points_possible: 10,
    position: 2,
  })

const assignment3 = () =>
  buildAssignment({
    id: 2,
    name: 'Science Quiz',
    points_possible: 5,
    position: 3,
  })

const buildGroup = (options = {}) => {
  const assignments = [assignment1(), assignment2(), assignment3()]
  const base = {
    id: 1,
    name: 'Assignments',
    position: 1,
    rules: {},
    group_weight: 1,
    assignments,
  }
  return {...base, ...options}
}

const createAssignmentGroup = (group = buildGroup()) => {
  const groups = new AssignmentGroupCollection([group])
  return groups.models[0]
}

const createView = (model, options = {}) => {
  options = {
    canManage: true,
    ...options,
  }

  ENV.PERMISSIONS = {
    manage: options.canManage,
    manage_assignments_add: options.canAdd ?? options.canManage,
    manage_assignments_delete: options.canDelete ?? options.canManage,
  }
  ENV.SETTINGS = {}

  const view = new AssignmentGroupListItemView({
    model,
    course: new Backbone.Model({id: 1}),
    userIsAdmin: options.userIsAdmin,
  })
  view.$el.appendTo($('#fixtures'))
  view.render()

  return view
}

describe('AssignmentGroupListItemView', () => {
  let model
  let view

  beforeEach(() => {
    ENV.URLS = {sort_url: 'test'}
    document.body.innerHTML = '<div id="fixtures"></div>'
    model = createAssignmentGroup()
  })

  afterEach(() => {
    view?.$el.remove()
    document.getElementById('fixtures').innerHTML = ''
  })

  describe('SIS integration', () => {
    it('shows imported icon when sis_source_id is not empty', () => {
      model.set('sis_source_id', '1234')
      view = createView(model)

      const sisIcon = document.querySelector(
        `#assignment_group_${model.id} .ig-header-title .icon-sis-imported`,
      )
      expect(sisIcon).toBeInTheDocument()
    })

    it('shows imported icon with custom SIS_NAME when sis_source_id is not empty', () => {
      ENV.SIS_NAME = 'PowerSchool'
      model.set('sis_source_id', '1234')
      view = createView(model)

      const sisIcon = document.querySelector(
        `#assignment_group_${model.id} .ig-header-title .icon-sis-imported`,
      )
      expect(sisIcon).toHaveAttribute('title', 'Imported from PowerSchool')
    })

    it('does not show imported icon when sis_source_id is not set', () => {
      view = createView(model)

      const sisIcon = document.querySelector(
        `#assignment_group_${model.id} .ig-header-title .icon-sis-imported`,
      )
      expect(sisIcon).not.toBeInTheDocument()
    })

    it('shows link icon when integration_data contains sistemic mapping', () => {
      model.set('integration_data', {sistemic: {categoryMapping: {abc: {}}}})
      view = createView(model)

      const linkIcon = document.querySelector(
        `#assignment_group_${model.id} .ig-header-title .icon-link`,
      )
      expect(linkIcon).toBeInTheDocument()
      expect(linkIcon).toHaveAttribute('title', 'Grading category aligned with SIS')
    })

    it('does not show link icon when integration_data does not contain sistemic mapping', () => {
      model.set('integration_data', {other: {id: '1234'}})
      view = createView(model)

      const linkIcon = document.querySelector(
        `#assignment_group_${model.id} .ig-header-title .icon-link`,
      )
      expect(linkIcon).not.toBeInTheDocument()
    })
  })

  describe('group management', () => {
    it('initializes with a collection', () => {
      view = createView(model)
      expect(view.collection).toBeTruthy()
    })

    it('allows deleting groups with assignments due in closed grading periods for admins', () => {
      model.set('any_assignment_in_closed_grading_period', true)
      view = createView(model, {userIsAdmin: true})

      const deleteButton = document.querySelector(
        `#assignment_group_${model.id} a.delete_group:not(.disabled)`,
      )
      expect(deleteButton).toBeInTheDocument()
    })

    it('provides delete option when canDelete is true', () => {
      jest.spyOn(model, 'canDelete').mockReturnValue(true)
      model.set('any_assignment_in_closed_grading_period', true)
      view = createView(model)

      const deleteButton = document.querySelector(`#assignment_group_${model.id} a.delete_group`)
      expect(deleteButton).toBeInTheDocument()
      expect(deleteButton).not.toHaveClass('disabled')
    })
  })
})
