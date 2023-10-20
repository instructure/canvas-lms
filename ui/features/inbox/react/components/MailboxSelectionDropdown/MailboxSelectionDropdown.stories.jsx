/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {MailboxSelectionDropdown} from './MailboxSelectionDropdown'

export default {
  title: 'Examples/Canvas Inbox/MailboxSelectionDropdown',
  component: MailboxSelectionDropdown,
  argTypes: {
    onSelect: {action: 'Changed'},
  },
}

const Template = args => <MailboxSelectionDropdown {...args} />

export const InboxSelected = Template.bind({})
InboxSelected.args = {
  activeMailbox: 'inbox',
}

export const UnreadSelected = Template.bind({})
UnreadSelected.args = {
  activeMailbox: 'unread',
}
