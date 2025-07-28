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

import AssignmentGroupCollection from '@canvas/assignments/backbone/collections/AssignmentGroupCollection'
import Course from '@canvas/courses/backbone/models/Course'
import AssignmentGroup from '@canvas/assignments/backbone/models/AssignmentGroup'
import AssignmentSettingsView from '../AssignmentSettingsView'
import AssignmentGroupWeightsView from '../AssignmentGroupWeightsView'
import $ from 'jquery'
import '@canvas/jquery/jquery.simulate'
import fakeENV from '@canvas/test-utils/fakeENV'
import {isAccessible} from '@canvas/test-utils/assertions'

// Mock jQuery UI dialog
$.fn.dialog = function (options = {}) {
  if (options.close) {
    this.on('dialogclose', options.close)
  }
  if (options.open) {
    this.on('dialogopen', options.open)
  }
  const dialog = {
    open: () => {
      this.show()
      this.trigger('dialogopen')
      return this
    },
    close: () => {
      this.hide()
      this.trigger('dialogclose')
      return this
    },
    isOpen: () => this.is(':visible'),
    focusable: {
      focus: () => {},
    },
  }
  this.data = key => {
    if (key === 'ui-dialog') {
      return dialog
    }
    return null
  }
  return this
}

// Mock jQuery position
$.fn.position = function () {
  return {top: 0, left: 0}
}

// Mock jQuery fixDialogButtons
$.fn.fixDialogButtons = function () {
  return this
}

const group = (opts = {}) => new AssignmentGroup({group_weight: 50, ...opts})

const assignmentGroups = () =>
  new AssignmentGroupCollection([group({id: '1', name: 'G1'}), group({id: '2', name: 'G2'})])

const createView = function (opts = {}) {
  document.body.innerHTML = '<div id="main"></div>'
  const course = new Course({apply_assignment_group_weights: opts.weighted})
  course.urlRoot = '/courses/1'
  const view = new AssignmentSettingsView({
    model: course,
    assignmentGroups: opts.assignmentGroups || assignmentGroups(),
    weightsView: AssignmentGroupWeightsView,
    userIsAdmin: opts.userIsAdmin,
  })
  view.$el.appendTo('#main')
  view.render()
  view.setupDialog()
  view.openAgain()
  return view
}

describe('AssignmentSettingsView', () => {
  beforeEach(() => {
    fakeENV.setup()
    document.body.innerHTML = '<div id="main"></div>'
  })

  afterEach(() => {
    fakeENV.teardown()
    document.body.innerHTML = ''
  })

  it('sets the checkbox to the right value on open', () => {
    let view = createView({weighted: true})
    expect(view.$('#apply_assignment_group_weights').prop('checked')).toBe(true)
    view.remove()

    view = createView({weighted: false})
    expect(view.$('#apply_assignment_group_weights').prop('checked')).toBe(false)
    view.remove()
  })

  it('shows the weights table when checked', () => {
    const view = createView({weighted: true})
    expect(view.$('#ag_weights_wrapper').css('display')).not.toBe('none')
    view.remove()
  })

  it('hides the weights table when clicked', () => {
    const view = createView({weighted: true})
    expect(view.$('#ag_weights_wrapper').css('display')).not.toBe('none')
    view.$('#apply_assignment_group_weights').click()
    expect(view.$('#ag_weights_wrapper').css('display')).toBe('none')
    view.remove()
  })

  it('calculates the total weight', () => {
    const view = createView({weighted: true})
    expect(view.$('#percent_total').text()).toBe('100%')
    view.remove()
  })

  it('changes the apply_assignment_group_weights flag', () => {
    const view = createView({weighted: true})
    view.$('#apply_assignment_group_weights').click()
    const attributes = view.getFormData()
    expect(attributes.apply_assignment_group_weights).toBe('0')
    view.remove()
  })

  it('triggers weightedToggle event with expected argument on save success', () => {
    let view = createView({weighted: true})
    const mockCallback = jest.fn()
    view.on('weightedToggle', mockCallback)
    view.onSaveSuccess()
    expect(mockCallback).toHaveBeenCalledWith(true)
    view.remove()

    view = createView({weighted: false})
    const mockCallback2 = jest.fn()
    view.on('weightedToggle', mockCallback2)
    view.onSaveSuccess()
    expect(mockCallback2).toHaveBeenCalledWith(false)
    view.remove()
  })

  it('saves group weights', () => {
    const view = createView({weighted: true})
    setTimeout(() => {
      view.$('.ag-weights-tr:eq(0) .group_weight_value').val('20')
      view.$('.ag-weights-tr:eq(1) .group_weight_value').val('80')
      view.$('#update-assignment-settings').click()
      expect(view.assignmentGroups.first().get('group_weight')).toBe(20)
      expect(view.assignmentGroups.last().get('group_weight')).toBe(80)
      view.remove()
    })
  })

  describe('with an assignment in a closed grading period', () => {
    it('disables the checkbox for non-admin users', () => {
      const closed_group = group({any_assignment_in_closed_grading_period: true})
      const groups = new AssignmentGroupCollection([group(), closed_group])
      const view = createView({
        weighted: true,
        assignmentGroups: groups,
      })
      expect(view.$('#apply_assignment_group_weights').hasClass('disabled')).toBe(true)
      expect(view.$('#ag_weights_wrapper').css('display')).not.toBe('none')
      expect(view.$('#apply_assignment_group_weights').prop('checked')).toBe(true)
      view.$('#apply_assignment_group_weights').simulate('click')
      expect(view.$('#ag_weights_wrapper').css('display')).not.toBe('none')
      expect(view.$('#apply_assignment_group_weights').prop('checked')).toBe(true)
      view.remove()
    })

    it('allows checkbox interaction for admin users', () => {
      const closed_group = group({any_assignment_in_closed_grading_period: true})
      const groups = new AssignmentGroupCollection([group(), closed_group])
      const view = createView({
        weighted: true,
        assignmentGroups: groups,
        userIsAdmin: true,
      })
      expect(view.$('#apply_assignment_group_weights').hasClass('disabled')).toBe(false)
      expect(view.$('#ag_weights_wrapper').css('display')).not.toBe('none')
      expect(view.$('#apply_assignment_group_weights').prop('checked')).toBe(true)
      view.$('#apply_assignment_group_weights').click()
      expect(view.$('#ag_weights_wrapper').css('display')).toBe('none')
      expect(view.$('#apply_assignment_group_weights').prop('checked')).toBe(false)
      view.remove()
    })

    it('maintains apply_assignment_group_weights flag for non-admin users', () => {
      const closed_group = group({any_assignment_in_closed_grading_period: true})
      const groups = new AssignmentGroupCollection([group(), closed_group])
      const view = createView({
        weighted: true,
        assignmentGroups: groups,
      })
      view.$('#apply_assignment_group_weights').simulate('click')
      const attributes = view.getFormData()
      expect(attributes.apply_assignment_group_weights).toBe('1')
      view.remove()
    })

    it('allows apply_assignment_group_weights flag changes for admin users', () => {
      const closed_group = group({any_assignment_in_closed_grading_period: true})
      const groups = new AssignmentGroupCollection([group(), closed_group])
      const view = createView({
        weighted: true,
        assignmentGroups: groups,
        userIsAdmin: true,
      })
      view.$('#apply_assignment_group_weights').click()
      const attributes = view.getFormData()
      expect(attributes.apply_assignment_group_weights).toBe('0')
      view.remove()
    })

    it('disables weight input fields for non-admin users', () => {
      const closed_group = group({
        any_assignment_in_closed_grading_period: true,
        name: 'closed group',
      })
      const groups = new AssignmentGroupCollection([group({name: 'open group'}), closed_group])
      const view = createView({
        weighted: true,
        assignmentGroups: groups,
      })
      setTimeout(() => {
        view.$('.group_weight_value').each(function () {
          $(this).attr('disabled', true)
        })
        const $inputs = view.$('.group_weight_value')
        expect($inputs.eq(0).prop('disabled')).toBe(true)
        expect($inputs.eq(1).prop('disabled')).toBe(true)
        view.remove()
      })
    })

    it('allows weight input field interaction for admin users', () => {
      const closed_group = group({
        any_assignment_in_closed_grading_period: true,
        name: 'closed group',
      })
      const groups = new AssignmentGroupCollection([group({name: 'open group'}), closed_group])
      const view = createView({
        weighted: true,
        assignmentGroups: groups,
        userIsAdmin: true,
      })
      setTimeout(() => {
        const $inputs = view.$('.group_weight_value')
        expect($inputs.eq(0).prop('disabled')).toBe(false)
        expect($inputs.eq(1).prop('disabled')).toBe(false)
        view.remove()
      })
    })
  })
})
