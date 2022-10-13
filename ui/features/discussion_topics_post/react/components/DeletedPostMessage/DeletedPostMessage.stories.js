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

import {DeletedPostMessage} from './DeletedPostMessage'
import {ThreadingToolbar} from '../ThreadingToolbar/ThreadingToolbar'
import {ReplyInfo} from '../ReplyInfo/ReplyInfo'

export default {
  title: 'Examples/Discussion Posts/Components/DeletedPostMessage',
  component: DeletedPostMessage,
  argTypes: {},
}

const Template = args => <DeletedPostMessage {...args} />

export const Default = Template.bind({})
Default.args = {
  children: (
    <ThreadingToolbar>
      <ThreadingToolbar.Expansion
        onExpand={() => {}}
        expandText={<ReplyInfo replyCount={23} unreadCount={5} />}
        delimiterKey="expansion"
      />
    </ThreadingToolbar>
  ),
  deleterName: 'Rick Sanchez',
  timingDisplay: 'Jan 1 1:00pm',
  deletedTimingDisplay: 'Feb 2 2:00pm',
}
