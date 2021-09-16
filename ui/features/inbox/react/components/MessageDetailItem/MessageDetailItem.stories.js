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

import {MessageDetailItem} from './MessageDetailItem'

export default {
  title: 'Examples/Canvas Inbox/MessageDetailItem',
  component: MessageDetailItem,
  argTypes: {
    handleOptionSelect: {action: 'handleOptionSelect'}
  }
}

const Template = args => <MessageDetailItem {...args} />

export const WithMultipleRecipients = Template.bind({})
WithMultipleRecipients.args = {
  conversationMessage: {
    author: {name: 'Bob Barker'},
    recipients: [{name: 'Bob Barker'}, {name: 'Sally Ford'}, {name: 'Russel Franks'}],
    createdAt: 'November 5, 2020 at 2:25pm',
    body: 'This is the body text for the message.'
  },
  contextName: 'Fake Course 1'
}

export const WithOneRecipient = Template.bind({})
WithOneRecipient.args = {
  conversationMessage: {
    author: {name: 'Bob Barker'},
    recipients: [{name: 'Bob Barker'}, {name: 'Sally Ford'}],
    createdAt: 'November 5, 2020 at 2:25pm',
    body: 'This is the body text for the message.'
  },
  contextName: 'Fake Course 1'
}
