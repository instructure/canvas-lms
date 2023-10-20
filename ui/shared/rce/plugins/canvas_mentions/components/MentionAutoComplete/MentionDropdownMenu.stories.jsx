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
import MentionDropdownMenu from './MentionDropdownMenu'

export default {
  title: 'Examples/RCE Plugins/MentionDropdown/Menu',
  component: MentionDropdownMenu,
}

const Template = args => <MentionDropdownMenu onSelect={() => {}} show={true} {...args} />

export const Primary = Template.bind({})
Primary.args = {
  mentionOptions: [
    {
      id: 1,
      name: 'Jeffrey Johnson',
    },
    {
      id: 2,
      name: 'Matthew Lemon',
    },
    {
      id: 3,
      name: 'Rob Orton',
    },
    {
      id: 4,
      name: 'Davis Hyer',
    },
    {
      id: 5,
      name: 'Drake Harper',
    },
    {
      id: 6,
      name: 'Omar Soto-Fortuño',
    },
    {
      id: 7,
      name: 'Chawn Neal',
    },
    {
      id: 8,
      name: 'Mauricio Ribeiro',
    },
    {
      id: 9,
      name: 'Caleb Guanzon',
    },
    {
      id: 10,
      name: 'Jason Gillett',
    },
  ],
}

export const OneOption = Template.bind({})
OneOption.args = {
  mentionOptions: [
    {
      id: 1,
      name: 'Jeffrey Johnson',
    },
  ],
}

export const TwoOptions = Template.bind({})
TwoOptions.args = {
  mentionOptions: [
    {
      id: 1,
      name: 'Jeffrey Johnson',
    },
    {
      id: 2,
      name: 'Matthew Lemon',
    },
  ],
}

export const Empty = Template.bind({})
Empty.args = {
  mentionOptions: [],
}

export const NotShowing = Template.bind({})
NotShowing.args = {
  mentionOptions: [
    {
      id: 1,
      name: 'Jeffrey Johnson',
    },
    {
      id: 2,
      name: 'Matthew Lemon',
    },
  ],
  show: false,
}
