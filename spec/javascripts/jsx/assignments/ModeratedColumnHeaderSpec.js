/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import React from 'react'
import {mount} from 'enzyme'
import ModeratedColumnHeader from 'jsx/assignments/ModeratedColumnHeader'
import Constants from 'jsx/assignments/constants'

QUnit.module('ModeratedColumnHeader', {
  setup() {
    this.props = {
      markColumn: Constants.markColumnNames.MARK_ONE,
      currentSortDirection: Constants.sortDirections.DESCENDING,
      includeModerationSetHeaders: true,
      handleSortMark1: () => {},
      handleSortMark2: () => {},
      handleSortMark3: () => {},
      handleSelectAll: () => {},
      permissions: {
        viewGrades: true
      }
    }
  }
})

test('calls the handleSortMark1 function when mark1 sort is pressed', function() {
  const callback = this.spy()

  this.props.handleSortMark1 = callback
  this.props.includeModerationSetHeaders = false

  const wrapper = mount(
    <table>
      <ModeratedColumnHeader {...this.props} />
    </table>
  )
  wrapper
    .find('a')
    .at(0)
    .simulate('click')

  ok(callback.called)

  wrapper.unmount()
})

test('calls the handleSortMark2 function when mark2 sort is pressed', function() {
  const callback = this.spy()

  this.props.markColumn = Constants.markColumnNames.MARK_TWO
  this.props.handleSortMark2 = callback

  const wrapper = mount(
    <table>
      <ModeratedColumnHeader {...this.props} />
    </table>
  )
  wrapper
    .find('a')
    .at(1)
    .simulate('click')

  ok(callback.called)

  wrapper.unmount()
})

test('calls the handleSortMark3 function when mark3 sort is pressed', function() {
  const callback = this.spy()

  this.props.markColumn = Constants.markColumnNames.MARK_THREE
  this.props.currentSortDirection = Constants.sortDirections.DESCENDING
  this.props.handleSortMark3 = callback

  const wrapper = mount(
    <table>
      <ModeratedColumnHeader {...this.props} />
    </table>
  )
  wrapper
    .find('a')
    .at(2)
    .simulate('click')

  ok(callback.called)

  wrapper.unmount()
})

test('calls the handleSelectAll function when the select all checkbox is checked', function() {
  const callback = this.spy()

  this.props.handleSelectAll = callback
  const wrapper = mount(
    <table>
      <ModeratedColumnHeader {...this.props} />
    </table>
  )
  wrapper.find('input[type="checkbox"]').simulate('change')

  ok(callback.called)

  wrapper.unmount()
})

test('displays down arrow when sort direction is DESCENDING', function() {
  this.props.markColumn = Constants.markColumnNames.MARK_ONE
  this.props.sortDirection = Constants.sortDirections.DESCENDING
  this.props.includeModerationSetHeaders = false

  const wrapper = mount(
    <table>
      <ModeratedColumnHeader {...this.props} />
    </table>
  )
  const downArrowIcon = wrapper.find('.icon-mini-arrow-down')
  ok(downArrowIcon, 'finds the down arrow')

  wrapper.unmount()
})

test('displays up arrow when sort direction is ASCENDING', function() {
  this.props.markColumn = Constants.markColumnNames.MARK_ONE
  this.props.sortDirection = Constants.sortDirections.ASCENDING
  this.props.includeModerationSetHeaders = false

  const wrapper = mount(
    <table>
      <ModeratedColumnHeader {...this.props} />
    </table>
  )
  const upArrowIcon = wrapper.find('.icon-mini-arrow-up')

  ok(upArrowIcon, 'finds the up arrow')

  wrapper.unmount()
})

test('only shows two columns when includeModerationSetHeaders is false', function() {
  this.props.includeModerationSetHeaders = false

  const wrapper = mount(
    <table>
      <ModeratedColumnHeader {...this.props} />
    </table>
  )
  const headers = wrapper.find('.ColumnHeader__Item')

  equal(headers.length, 2, 'only shows two header columns')

  wrapper.unmount()
})

test('only shows all columns when includeModerationSetHeaders is true', function() {
  const wrapper = mount(
    <table>
      <ModeratedColumnHeader {...this.props} />
    </table>
  )
  const headers = wrapper.find('.ColumnHeader__Item')

  equal(headers.length, 5, 'show all headers when true')

  wrapper.unmount()
})

test('includes the checkbox if the user has permission to view grades', function() {
  const wrapper = mount(
    <table>
      <ModeratedColumnHeader {...this.props} />
    </table>
  )
  const checkboxes = wrapper.find('input[type="checkbox"]')

  equal(checkboxes.length, 1)

  wrapper.unmount()
})

test('does not include the checkbox if the user does not have permission to view grades', function() {
  this.props.permissions.viewGrades = false

  const wrapper = mount(
    <table>
      <ModeratedColumnHeader {...this.props} />
    </table>
  )
  const checkboxes = wrapper.find('input[type="checkbox"]')

  equal(checkboxes.length, 0)

  wrapper.unmount()
})

test('includes the checkbox if the user has permission to view grades without moderation set headers', function() {
  this.props.includeModerationSetHeaders = false

  const wrapper = mount(
    <table>
      <ModeratedColumnHeader {...this.props} />
    </table>
  )
  const checkboxes = wrapper.find('input[type="checkbox"]')

  equal(checkboxes.length, 1)

  wrapper.unmount()
})

test('does not include the checkbox if the user does not have permission to view grades without moderation set headers', function() {
  this.props.permissions.viewGrades = false
  this.props.includeModerationSetHeaders = false

  const wrapper = mount(
    <table>
      <ModeratedColumnHeader {...this.props} />
    </table>
  )
  const checkboxes = wrapper.find('input[type="checkbox"]')

  equal(checkboxes.length, 0)

  wrapper.unmount()
})
