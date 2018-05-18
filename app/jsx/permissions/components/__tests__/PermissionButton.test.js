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
import {mount} from 'enzyme'

import PermissionButton from '../PermissionButton'

const handlingClick = jest.fn()

const defaultProps = () => ({
  permission: {enabled: true, locked: false, readonly: false, explicit: true},
  permissionName: 'add',
  courseRoleId: '1',
  handleClick: handlingClick
})

const disabledProps = () => ({
  permission: {enabled: false, locked: false, readonly: false, explicit: true},
  permissionName: 'add',
  courseRoleId: '1',
  handleClick: handlingClick
})

const enabledAndLockedProps = () => ({
  permission: {enabled: true, locked: true, readonly: false, explicit: true},
  permissionName: 'add',
  courseRoleId: '1',
  handleClick: handlingClick
})

const disabledAndLockedProps = () => ({
  permission: {enabled: false, locked: true, readonly: false, explicit: true},
  permissionName: 'add',
  courseRoleId: '1',
  handleClick: handlingClick
})

it('component renders', () => {
  const tree = mount(<PermissionButton {...defaultProps()} />)

  const node = tree.find('PermissionButton')
  expect(node.exists()).toEqual(true)
})

it('displays enabled correctly', () => {
  const tree = mount(<PermissionButton {...defaultProps()} />)

  const check = tree.find('IconPublish')
  const x = tree.find('IconTrouble')
  const lock = tree.find('IconLock')

  expect(check.exists()).toEqual(true)
  expect(x.exists()).toEqual(false)
  expect(lock.exists()).toEqual(false)
})

it('displays disabled correctly', () => {
  const tree = mount(<PermissionButton {...disabledProps()} />)

  const check = tree.find('IconPublish')
  const x = tree.find('IconTrouble')
  const lock = tree.find('IconLock')

  expect(check.exists()).toEqual(false)
  expect(x.exists()).toEqual(true)
  expect(lock.exists()).toEqual(false)
})

it('displays enabled and locked correctly', () => {
  const tree = mount(<PermissionButton {...enabledAndLockedProps()} />)

  const check = tree.find('IconPublish')
  const x = tree.find('IconTrouble')
  const lock = tree.find('IconLock')

  expect(check.exists()).toEqual(true)
  expect(x.exists()).toEqual(false)
  expect(lock.exists()).toEqual(true)
})

it('displays disabled and locked correctly', () => {
  const tree = mount(<PermissionButton {...disabledAndLockedProps()} />)

  const check = tree.find('IconPublish')
  const x = tree.find('IconTrouble')
  const lock = tree.find('IconLock')

  expect(check.exists()).toEqual(false)
  expect(x.exists()).toEqual(true)
  expect(lock.exists()).toEqual(true)
})
