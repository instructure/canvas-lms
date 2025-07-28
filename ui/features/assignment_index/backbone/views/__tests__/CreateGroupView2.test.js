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

import $ from 'jquery'
import 'jquery-migrate'
import '@canvas/jquery/jquery.simulate'
import AssignmentGroupCollection from '@canvas/assignments/backbone/collections/AssignmentGroupCollection'
import AssignmentGroup from '@canvas/assignments/backbone/models/AssignmentGroup'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import Course from '@canvas/courses/backbone/models/Course'
import fakeENV from '@canvas/test-utils/fakeENV'
import CreateGroupView from '../CreateGroupView'
import {waitFor} from '@testing-library/react'

describe('CreateGroupView - Drop Rules', () => {
  let view = null
  let saveMock = null

  const group = (id, opts = {}) =>
    new AssignmentGroup({
      id: id,
      name: 'something cool',
      assignments: [new Assignment(), new Assignment()],
      ...opts,
    })

  const assignmentGroups = () => new AssignmentGroupCollection([group('0'), group('1')])

  const createView = function (opts = {}) {
    const groups = opts.assignmentGroups || assignmentGroups()
    const args = {
      course: opts.course || new Course({apply_assignment_group_weights: true}),
      assignmentGroups: groups,
      assignmentGroup: opts.group || (opts.newGroup == null ? groups.first() : undefined),
      userIsAdmin: opts.userIsAdmin,
    }
    return new CreateGroupView(args)
  }

  beforeEach(() => {
    fakeENV.setup()
    document.body.innerHTML = '<div id="fixtures"></div>'
  })

  afterEach(() => {
    fakeENV.teardown()
    if (view) {
      view.close()
      view.remove()
    }
    document.querySelectorAll('.ui-dialog').forEach(el => el.remove())
    document.body.innerHTML = ''
    jest.resetAllMocks()
  })

  test('it should not save drop rules when none are given', async () => {
    view = createView()
    const deferred = $.Deferred()
    saveMock = jest.spyOn(view.model, 'save').mockReturnValue(deferred)
    document.getElementById('fixtures').appendChild(view.el)

    view.render()
    view.firstOpen()

    await waitFor(() => {
      view.$('#ag_0_drop_lowest').val('')
      view.$('#ag_0_drop_highest').val('0')
      view.$('#ag_0_name').val('IchangedIt')
    })

    const submitPromise = view.submit()
    deferred.resolveWith(view.model, [{}, 'success'])
    await submitPromise

    const formData = view.getFormData()
    expect(formData.name).toBe('IchangedIt')
    expect(formData.rules).toEqual(undefined)
    expect(saveMock).toHaveBeenCalled()
  })

  test('it should save drop rules when given', async () => {
    view = createView()
    const deferred = $.Deferred()
    saveMock = jest.spyOn(view.model, 'save').mockReturnValue(deferred)
    document.getElementById('fixtures').appendChild(view.el)

    view.render()
    view.firstOpen()

    await waitFor(() => {
      view.$('#ag_0_drop_lowest').val('1')
      view.$('#ag_0_drop_highest').val('2')
      view.$('#ag_0_name').val('IchangedIt')
    })

    const submitPromise = view.submit()
    deferred.resolveWith(view.model, [{}, 'success'])
    await submitPromise

    const formData = view.getFormData()
    expect(formData.name).toBe('IchangedIt')
    expect(formData.rules).toEqual(undefined)
    expect(saveMock).toHaveBeenCalled()
  })
})
