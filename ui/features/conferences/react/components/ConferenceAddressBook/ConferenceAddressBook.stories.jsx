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

import {ConferenceAddressBook} from './ConferenceAddressBook'

const menuItemList = [
  {displayName: 'Allison Pitler', id: '7'},
  {displayName: 'Caleb Guanzon', id: '3'},
  {displayName: 'Chawn Neal', id: '2'},
  {displayName: 'Drake Harper', id: '1'},
  {displayName: 'Jason Gillet', id: '5'},
  {displayName: 'Jeffrey Johnson', id: '0'},
  {displayName: 'Jewel Pearson', id: '8'},
  {displayName: 'Nic Nolan', id: '6'},
  {displayName: 'Omar Soto Fortuno', id: '4'},
]

export default {
  title: 'Examples/Conferences/ConferenceAddressBook',
  component: ConferenceAddressBook,
  argTypes: {},
}

const Template = args => <ConferenceAddressBook menuItemList={menuItemList} {...args} />

export const Default = Template.bind({})
Default.args = {}

export const SelectedUsers = Template.bind({})
SelectedUsers.args = {
  selectedIds: ['1', '2', '3'],
}
