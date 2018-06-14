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
import {shallow} from 'enzyme'

import PermissionButton from '../PermissionButton'

const defaultProps = () => ({
  permission: {enabled: true, locked: false, readonly: false, explicit: true},
  permissionName: 'add',
  cleanFocus: () => {},
  inTray: false,
  setFocus: false,
  roleId: '1',
  fixButtonFocus: () => {},
  handleClick: () => {},
  useCaching: false
})

const disabledProps = () => ({
  permission: {enabled: false, locked: false, readonly: false, explicit: true},
  permissionName: 'add',
  cleanFocus: () => {},
  inTray: false,
  setFocus: false,
  roleId: '1',
  fixButtonFocus: () => {},
  handleClick: () => {},
  useCaching: false
})

const enabledAndLockedProps = () => ({
  permission: {enabled: true, locked: true, readonly: false, explicit: true},
  permissionName: 'add',
  cleanFocus: () => {},
  inTray: false,
  setFocus: false,
  roleId: '1',
  fixButtonFocus: () => {},
  handleClick: () => {},
  useCaching: false
})

const disabledAndLockedProps = () => ({
  permission: {enabled: false, locked: true, readonly: false, explicit: true},
  permissionName: 'add',
  cleanFocus: () => {},
  inTray: false,
  setFocus: false,
  roleId: '1',
  fixButtonFocus: () => {},
  handleClick: () => {},
  useCaching: false
})

const readOnly = () => ({
  permission: {enabled: false, locked: true, readonly: true, explicit: true},
  permissionName: 'add',
  cleanFocus: () => {},
  inTray: false,
  setFocus: false,
  roleId: '1',
  fixButtonFocus: () => {},
  handleClick: () => {},
  useCaching: false
})

it('displays enabled correctly', () => {
  const tree = shallow(<PermissionButton {...defaultProps()} />)

  const check = tree.find('IconPublish')
  const x = tree.find('IconTrouble')
  const hideLock = tree.find('.ic-hidden-button')

  expect(check.exists()).toEqual(true)
  expect(x.exists()).toEqual(false)
  expect(hideLock.exists()).toEqual(true)
})

it('displays disabled correctly', () => {
  const tree = shallow(<PermissionButton {...disabledProps()} />)

  const check = tree.find('IconPublish')
  const x = tree.find('IconTrouble')
  const hideLock = tree.find('.ic-hidden-button')

  expect(check.exists()).toEqual(false)
  expect(x.exists()).toEqual(true)
  expect(hideLock.exists()).toEqual(true)
})

it('displays enabled and locked correctly', () => {
  const tree = shallow(<PermissionButton {...enabledAndLockedProps()} />)

  const check = tree.find('IconPublish')
  const x = tree.find('IconTrouble')
  const hideLock = tree.find('.ic-hidden-button')

  expect(check.exists()).toEqual(true)
  expect(x.exists()).toEqual(false)
  expect(hideLock.exists()).toEqual(false)
})

it('displays disabled and locked correctly', () => {
  const tree = shallow(<PermissionButton {...disabledAndLockedProps()} />)

  const check = tree.find('IconPublish')
  const x = tree.find('IconTrouble')
  const hideLock = tree.find('.ic-hidden-button')

  expect(check.exists()).toEqual(false)
  expect(x.exists()).toEqual(true)
  expect(hideLock.exists()).toEqual(false)
})

it('displays disabled when permission is readonly', () => {
  const tree = shallow(<PermissionButton {...readOnly()} />)
  const button = tree.find('button')
  expect(button.props().disabled).toEqual(true)
})
