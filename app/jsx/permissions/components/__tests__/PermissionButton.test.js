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

import React from 'react'
import {shallow, mount} from 'enzyme'

import PermissionButton from '../PermissionButton'

const defaultProps = () => ({
  permission: {enabled: true, locked: false, readonly: false, explicit: true},
  permissionName: 'add',
  permissionLabel: 'add',
  cleanFocus: () => {},
  inTray: false,
  setFocus: false,
  roleId: '1',
  roleLabel: 'myRole',
  fixButtonFocus: () => {},
  handleClick: () => {}
})

const disabledProps = () => ({
  permission: {enabled: false, locked: false, readonly: false, explicit: true},
  permissionName: 'add',
  permissionLabel: 'add',
  cleanFocus: () => {},
  inTray: false,
  setFocus: false,
  roleId: '1',
  roleLabel: 'myRole',
  fixButtonFocus: () => {},
  handleClick: () => {}
})

const enabledAndLockedProps = () => ({
  permission: {enabled: true, locked: true, readonly: false, explicit: true},
  permissionName: 'add',
  permissionLabel: 'add',
  cleanFocus: () => {},
  inTray: false,
  setFocus: false,
  roleId: '1',
  roleLabel: 'myRole',
  fixButtonFocus: () => {},
  handleClick: () => {}
})

const disabledAndLockedProps = () => ({
  permission: {enabled: false, locked: true, readonly: false, explicit: true},
  permissionName: 'add',
  permissionLabel: 'add',
  cleanFocus: () => {},
  inTray: false,
  setFocus: false,
  roleId: '1',
  roleLabel: 'myRole',
  fixButtonFocus: () => {},
  handleClick: () => {}
})

const readOnly = () => ({
  permission: {enabled: false, locked: true, readonly: true, explicit: true},
  permissionName: 'add',
  permissionLabel: 'add',
  cleanFocus: () => {},
  inTray: false,
  setFocus: false,
  roleId: '1',
  roleLabel: 'myRole',
  fixButtonFocus: () => {},
  handleClick: () => {}
})

it('displays enabled correctly', () => {
  const tree = mount(<PermissionButton {...defaultProps()} />)

  const check = tree.getDOMNode().querySelector('svg[name="IconPublish"]')
  const x = tree.getDOMNode().querySelector('svg[name="IconTrouble"]')
  const hideLock = tree.find('.ic-hidden-button')

  expect(check).toBeTruthy()
  expect(x).toBeNull()
  expect(hideLock.exists()).toEqual(true)
})

it('displays disabled correctly', () => {
  const tree = mount(<PermissionButton {...disabledProps()} />)

  const check = tree.getDOMNode().querySelector('svg[name="IconPublish"]')
  const x = tree.getDOMNode().querySelector('svg[name="IconTrouble"]')
  const hideLock = tree.find('.ic-hidden-button')

  expect(check).toBeNull()
  expect(x).not.toBeNull()
  expect(hideLock.exists()).toEqual(true)
})

it('displays screenreader disabled correctly', () => {
  const stateOfButton = 'Disabled'
  const permissionLabel = 'Venks Awesome'
  const props = disabledProps()
  props.permissionLabel = 'Venks Awesome'
  const tree = shallow(<PermissionButton {...props} />)

  expect(tree.find('button').prop('aria-label')).toEqual(
    `${stateOfButton} ${permissionLabel} myRole`
  )
})

it('displays screenreader disabled and locked correctly', () => {
  const stateOfButton = 'Disabled and Locked'
  const permissionLabel = 'Venks Great'
  const props = disabledAndLockedProps()
  props.permissionLabel = 'Venks Great'
  const tree = shallow(<PermissionButton {...props} />)

  expect(tree.find('button').prop('aria-label')).toEqual(
    `${stateOfButton} ${permissionLabel} myRole`
  )
})

it('displays screenreader enabled and locked correctly', () => {
  const stateOfButton = 'Enabled and Locked'
  const permissionLabel = 'Venks Fun'
  const props = enabledAndLockedProps()
  props.permissionLabel = 'Venks Fun'
  const tree = shallow(<PermissionButton {...props} />)

  expect(tree.find('button').prop('aria-label')).toEqual(
    `${stateOfButton} ${permissionLabel} myRole`
  )
})

it('displays screenreader enabled correctly', () => {
  const stateOfButton = 'Enabled'
  const permissionLabel = 'Everything is Awesome!!'
  const props = defaultProps()
  props.permissionLabel = 'Everything is Awesome!!'
  const tree = shallow(<PermissionButton {...props} />)
  expect(tree.find('button').prop('aria-label')).toEqual(
    `${stateOfButton} ${permissionLabel} myRole`
  )
})

it('displays enabled and locked correctly', () => {
  const tree = mount(<PermissionButton {...enabledAndLockedProps()} />)

  const check = tree.getDOMNode().querySelector('svg[name="IconPublish"]')
  const x = tree.getDOMNode().querySelector('svg[name="IconTrouble"]')
  const hideLock = tree.find('.ic-hidden-button')

  expect(check).toBeTruthy()
  expect(x).toBeNull()
  expect(hideLock.exists()).toEqual(false)
})

it('displays disabled and locked correctly', () => {
  const tree = mount(<PermissionButton {...disabledAndLockedProps()} />)

  const check = tree.getDOMNode().querySelector('svg[name="IconPublish"]')
  const x = tree.getDOMNode().querySelector('svg[name="IconTrouble"]')
  const hideLock = tree.find('.ic-hidden-button')

  expect(check).toBeNull()
  expect(x).toBeTruthy()
  expect(hideLock.exists()).toEqual(false)
})

it('displays disabled when permission is readonly', () => {
  const tree = shallow(<PermissionButton {...readOnly()} />)
  const button = tree.find('button')
  expect(button.props().disabled).toEqual(true)
})
