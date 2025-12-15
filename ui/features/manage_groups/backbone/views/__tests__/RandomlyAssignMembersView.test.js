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
import GroupCategory from '@canvas/groups/backbone/models/GroupCategory'
import RandomlyAssignMembersView from '../RandomlyAssignMembersView'
import fakeENV from '@canvas/test-utils/fakeENV'

// Mock the ProgressBar component to avoid screenReaderLabel prop warning
vi.mock('@instructure/ui-progress', () => ({
  ProgressBar: () => null,
}))

// Mock jQuery UI dialog
const dialogStub = {
  focusable: {
    focus: () => {},
  },
  open: () => {},
  close: () => {},
  isOpen: () => false,
}

$.fn.dialog = function (options) {
  if (options) {
    this.data('ui-dialog', dialogStub)
  }
  return this
}

$.fn.fixDialogButtons = function () {
  return this
}

describe('RandomlyAssignMembersView', () => {
  let model
  let randomlyAssignView

  beforeEach(() => {
    fakeENV.setup({
      group_user_type: 'student',
      permissions: {can_manage_groups: true},
      IS_LARGE_ROSTER: false,
    })

    document.body.innerHTML = '<div id="fixtures"><div id="content"></div></div>'

    // Mock jQuery methods needed for dialog positioning
    $.fn.extend({
      offset: () => ({top: 0, left: 0}),
      position: () => ({top: 0, left: 0}),
      outerHeight: () => 100,
      outerWidth: () => 100,
      scrollLeft: () => 0,
      scrollTop: () => 0,
      height: () => 100,
      width: () => 100,
      show: function () {
        this.css('display', 'block')
        return this
      },
      hide: function () {
        this.css('display', 'none')
        return this
      },
      is: function (selector) {
        if (selector === ':visible') {
          return this.css('display') !== 'none'
        }
        return false
      },
    })

    // Create model with groups_count=0 to prevent auto-fetch
    model = new GroupCategory({id: 20, name: 'Project Group', groups_count: 0})

    // Create the RandomlyAssignMembersView directly (no need for GroupCategoryView)
    randomlyAssignView = new RandomlyAssignMembersView({model})
  })

  afterEach(() => {
    // Stop backbone from listening to events before teardown to prevent
    // async callbacks from accessing ENV after teardown
    model.off()
    if (model._groups) {
      model._groups.off()
    }
    if (model._unassignedUsers) {
      model._unassignedUsers.off()
    }
    randomlyAssignView?.remove()
    fakeENV.teardown()
    document.body.innerHTML = ''
    vi.clearAllTimers()
    vi.useRealTimers()
  })

  describe('toggleSectionInfo', () => {
    beforeEach(() => {
      // Open the dialog to render the template
      randomlyAssignView?.open()
    })

    afterEach(() => {
      randomlyAssignView?.close()
    })

    it('shows info box when checkbox is checked', () => {
      const $checkbox = randomlyAssignView.$('input[name=group_by_section]')
      const $infoBox = randomlyAssignView.$('#group-by-section-info')

      // Initially, info box should be hidden
      expect($infoBox.css('display')).toBe('none')

      // Check the checkbox and trigger change event
      $checkbox.prop('checked', true).trigger('change')

      // Info box should now be visible (display should not be 'none')
      expect($infoBox.css('display')).not.toBe('none')
      expect($infoBox.is(':visible')).toBe(true)
    })

    it('hides info box when checkbox is unchecked', () => {
      const $checkbox = randomlyAssignView.$('input[name=group_by_section]')
      const $infoBox = randomlyAssignView.$('#group-by-section-info')

      // First check the checkbox to show the info box
      $checkbox.prop('checked', true).trigger('change')
      expect($infoBox.css('display')).not.toBe('none')

      // Now uncheck the checkbox
      $checkbox.prop('checked', false).trigger('change')

      // Info box should be hidden
      expect($infoBox.css('display')).toBe('none')
      expect($infoBox.is(':visible')).toBe(false)
    })

    it('toggles info box visibility multiple times correctly', () => {
      const $checkbox = randomlyAssignView.$('input[name=group_by_section]')
      const $infoBox = randomlyAssignView.$('#group-by-section-info')

      // Initially hidden
      expect($infoBox.css('display')).toBe('none')

      // Check -> should show
      $checkbox.prop('checked', true).trigger('change')
      expect($infoBox.css('display')).not.toBe('none')
      expect($infoBox.is(':visible')).toBe(true)

      // Uncheck -> should hide
      $checkbox.prop('checked', false).trigger('change')
      expect($infoBox.css('display')).toBe('none')
      expect($infoBox.is(':visible')).toBe(false)

      // Check again -> should show
      $checkbox.prop('checked', true).trigger('change')
      expect($infoBox.css('display')).not.toBe('none')
      expect($infoBox.is(':visible')).toBe(true)
    })

    it('contains the correct info text', () => {
      randomlyAssignView.open()
      const infoBox = randomlyAssignView.$('#group-by-section-info')

      expect(infoBox.text()).toContain(
        'Students who are enrolled in multiple sections will be put in a group by themselves',
      )
      expect(infoBox.hasClass('alert')).toBe(true)
      expect(infoBox.hasClass('alert-info')).toBe(true)
    })

    it('has proper accessibility attributes', () => {
      randomlyAssignView.open()
      const infoBox = randomlyAssignView.$('#group-by-section-info')
      const icon = infoBox.find('i.icon-info')

      expect(icon.attr('aria-hidden')).toBe('true')
      expect(infoBox.attr('id')).toBe('group-by-section-info')
    })
  })
})
