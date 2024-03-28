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

import {ChildTopic} from '../../../graphql/ChildTopic'
import {DiscussionPostToolbar, getMenuConfig} from './DiscussionPostToolbar'

export default {
  title: 'Examples/Discussion Posts/Components/Discussion Post Toolbar',
  component: DiscussionPostToolbar,
  parameters: {actions: {argTypesRegex: '^on.*'}},
  argTypes: {
    selectedView: {
      control: {
        type: 'select',
        options: Object.keys(getMenuConfig({enableDeleteFilter: true})),
      },
    },
    sortDirection: {
      control: {
        type: 'select',
        options: ['asc', 'desc'],
      },
    },
  },
}

const Template = args => <DiscussionPostToolbar {...args} />

export const Default = Template.bind({})

export const SortedDesc = Template.bind({})
SortedDesc.args = {
  sortDirection: 'desc',
}

export const ShowDeleted = Template.bind({})
ShowDeleted.args = {
  enableDeleteFilter: true,
}

export const WithChildTopics = Template.bind({})
WithChildTopics.args = {
  childTopics: [
    ChildTopic.mock(),
    ChildTopic.mock({
      _id: '2',
      contextName: 'Group 2',
      contextId: '2',
      entryCounts: {unreadCount: 0},
    }),
    ChildTopic.mock({
      _id: '3',
      contextName: 'Group 3',
      contextId: '3',
      entryCounts: {unreadCount: 0},
    }),
  ],
}
