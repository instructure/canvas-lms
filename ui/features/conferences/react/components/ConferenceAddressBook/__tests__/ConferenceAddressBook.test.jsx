// @vitest-environment jsdom
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

import React from 'react'
import {fireEvent, render} from '@testing-library/react'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'
import {ConferenceAddressBook} from '../ConferenceAddressBook'

injectGlobalAlertContainers()

describe('ConferenceAddressBook', () => {
  afterEach(() => {
    window.ENV.sections = []
    window.ENV.section_user_ids_map = {}
    window.ENV.groups = []
    window.ENV.group_user_ids_map = {}
  })

  const menuItemList = [
    {displayName: 'Allison', id: '7', type: 'user', assetCode: 'user-7'},
    {displayName: 'Caleb', id: '3', type: 'user', assetCode: 'user-3'},
    {displayName: 'Chawn', id: '2', type: 'user', assetCode: 'user-2'},
    {displayName: 'Group1', id: '23', type: 'group', assetCode: 'group-23'},
    {displayName: 'Section1', id: '24', type: 'section', assetCode: 'section-24'},
  ]

  const setup = (props = {}, menuList = menuItemList) => {
    return render(<ConferenceAddressBook menuItemList={menuList} {...props} />)
  }

  it('should render', () => {
    const container = setup()
    expect(container).toBeTruthy()
  })

  it('should open when clicked', () => {
    const container = setup()
    const input = container.getByTestId('address-input')
    input.click()
    const item = container.getByText('Allison')
    expect(item).toBeTruthy()
  })

  it('should filter when input is recieved', () => {
    const container = setup()
    const input = container.getByTestId('address-input')
    fireEvent.change(input, {target: {value: 'Caleb'}})
    const item = container.queryByText('Allison')
    expect(item).toBeFalsy()
  })

  it('should add tag when user is selected', () => {
    const container = setup()
    const input = container.getByTestId('address-input')
    input.click()
    const item = container.getByText('Allison')
    item.click()
    const tag = container.getByTestId('address-tag')
    expect(tag).toBeTruthy()
  })

  it('should add tag when group is selected', () => {
    const container = setup()
    const input = container.getByTestId('address-input')
    input.click()
    const item = container.getByText('Group1')
    item.click()
    const tag = container.getByTestId('address-tag')
    expect(tag).toBeTruthy()
  })

  it('should add tag when section is selected', () => {
    const container = setup()
    const input = container.getByTestId('address-input')
    input.click()
    const item = container.getByText('Section1')
    item.click()
    const tag = container.getByTestId('address-tag')
    expect(tag).toBeTruthy()
  })

  it('should have section header when section is present', () => {
    const container = setup()
    const input = container.getByTestId('address-input')
    input.click()
    const item = container.getByTestId('section-conference-header')
    expect(item).toBeTruthy()
  })

  it('should have group header when group is present', () => {
    const container = setup()
    const input = container.getByTestId('address-input')
    input.click()
    const item = container.getByTestId('group-conference-header')
    expect(item).toBeTruthy()
  })

  it('should not have group header when no groups exist', () => {
    const menuItemList = [
      {displayName: 'Allison', id: '7', type: 'user', assetCode: 'user-7'},
      {displayName: 'Caleb', id: '3', type: 'user', assetCode: 'user-3'},
      {displayName: 'Chawn', id: '2', type: 'user', assetCode: 'user-2'},
      {displayName: 'Section1', id: '24', type: 'section', assetCode: 'section-24'},
    ]
    const container = setup({}, menuItemList)
    const input = container.getByTestId('address-input')
    input.click()
    const item = container.queryByTestId('group-conference-header')
    expect(item).toBeFalsy()
  })

  it('should have User header', () => {
    const container = setup()
    const input = container.getByTestId('address-input')
    input.click()
    const item = container.getByTestId('user-conference-header')
    expect(item).toBeTruthy()
  })

  it('should render initial tags when selectedIds is passed', () => {
    const container = setup({
      selectedItems: [{displayName: 'Chawn', id: '2', type: 'user', assetCode: 'user-2'}],
    })
    const tag = container.getByTestId('address-tag')
    expect(tag).toBeTruthy()
  })

  it('should initially render groups that have all users selected', () => {
    window.ENV.groups = [{displayName: 'Group1', id: '23'}]
    window.ENV.group_user_ids_map = {23: ['2']}
    const container = setup({
      selectedItems: [{displayName: 'Chawn', id: '2', type: 'user', assetCode: 'user-2'}],
    })
    const tag = container.getAllByTestId('address-tag')
    expect(tag).toBeTruthy()
    expect(tag.length).toBe(2)
  })

  it('should initially render sections that have all users selected', () => {
    window.ENV.sections = [{displayName: 'Section1', id: '24'}]
    window.ENV.section_user_ids_map = {24: ['2']}
    const container = setup({
      selectedItems: [{displayName: 'Chawn', id: '2', type: 'user', assetCode: 'user-2'}],
    })
    const tag = container.getAllByTestId('address-tag')
    expect(tag).toBeTruthy()
    expect(tag.length).toBe(2)
  })

  it('should remove selected user when backspace is pressed and input is empty', () => {
    const container = setup()
    const input = container.getByTestId('address-input')
    input.click()
    const item = container.getByText('Allison')
    item.click()
    fireEvent.keyDown(input, {keyCode: '8'})
    const tag = container.queryByTestId('address-tag')
    expect(tag).toBeFalsy()
  })

  it('should not remove saved users when isEditing', () => {
    const container = setup({isEditing: true, selectedItems: [menuItemList[0]]})
    const input = container.getByTestId('address-input')
    input.click()
    const item = container.getByText('Allison')
    item.click()
    fireEvent.keyDown(input, {keyCode: '8'})
    const tag = container.queryByTestId('address-tag')
    expect(tag).toBeTruthy()
    tag.click()
    expect(tag).toBeTruthy()
  })

  it('should remove unsaved users when isEditing', () => {
    const container = setup({isEditing: true, selectedItems: []})
    const input = container.getByTestId('address-input')
    input.click()
    const item = container.getByText('Allison')
    item.click()
    fireEvent.keyDown(input, {keyCode: '8'})
    const tag = container.queryByTestId('address-tag')
    expect(tag).toBeFalsy()
  })
})
