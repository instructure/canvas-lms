/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {AddressBook} from './AddressBook'

const demoData = [
  {id: 'course_11', name: 'Test 101'},
  {id: 'course_12', name: 'History 101'},
  {id: 'course_13', name: 'English 101'},
  {id: '1', name: 'Rob Orton', full_name: 'Rob Orton', pronouns: null},
  {id: '2', name: 'Matthew Lemon', full_name: 'Matthew Lemon', pronouns: null},
  {id: '3', name: 'Drake Harper', full_name: 'Drake Harpert', pronouns: null},
  {id: '4', name: 'Davis Hyer', full_name: 'Davis Hyer', pronouns: null},
]

export default {
  title: 'Examples/Canvas Inbox/AddressBook',
  component: AddressBook,
  argTypes: {
    onSelect: {action: 'onSelect'},
  },
}

const Template = args => <AddressBook {...args} />

export const Default = Template.bind({})
Default.args = {
  menuData: demoData,
}

export const HasSubMenu = Template.bind({})
HasSubMenu.args = {isSubMenu: true, menuData: demoData}

export const IsLoading = Template.bind({})
IsLoading.args = {isLoading: true, menuData: demoData}

export const LimitOfOne = Template.bind({})
LimitOfOne.args = {limitTagCount: 1, menuData: demoData}

export const NoResults = Template.bind({})
NoResults.args = {menuData: []}

export const WithHeader = Template.bind({})
WithHeader.args = {headerText: 'Example Course', isSubMenu: true, menuData: demoData}

export const WithOneItem = Template.bind({})
WithOneItem.args = {menuData: [demoData[0]]}

export const FullWidth = Template.bind({})
FullWidth.args = {width: '100%', menuData: demoData}

export const AdjustedWidth = Template.bind({})
AdjustedWidth.args = {width: '350px', menuData: demoData}

export const ForcedOpen = Template.bind({})
ForcedOpen.args = {width: '350px', menuData: demoData, open: true}
