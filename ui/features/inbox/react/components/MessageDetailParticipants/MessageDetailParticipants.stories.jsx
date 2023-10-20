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

import {MessageDetailParticipants} from './MessageDetailParticipants'

export default {
  title: 'Examples/Canvas Inbox/MessageDetailParticipants',
  component: MessageDetailParticipants,
}

const Template = args => <MessageDetailParticipants {...args} />

export const WithMultipleRecipients = Template.bind({})
WithMultipleRecipients.args = {
  conversationMessage: {
    author: {name: 'Bob Barker'},
    recipients: [
      {name: 'Bob Barker'},
      {name: 'Sally Ford'},
      {name: 'Russel Franks'},
      {name: 'Dipali Vega'},
      {name: 'Arlet Tuân'},
      {name: 'Tshepo Jehoiachin'},
      {name: 'Ráichéal Mairead'},
      {name: 'Renāte Tarik'},
      {name: "Jocelin 'Avshalom"},
      {name: 'Marisa Ninurta'},
      {name: 'Régine Teige'},
      {name: 'Norman Iustina'},
      {name: 'Ursula Siddharth'},
      {name: 'Cristoforo Gülnarə'},
      {name: 'Katka Lauge'},
      {name: 'Sofia Fernanda'},
      {name: 'Orestes Etheldreda'},
    ],
    createdAt: 'November 5, 2020 at 2:25pm',
    body: 'This is the body text for the message.',
  },
}

export const WithOneRecipient = Template.bind({})
WithOneRecipient.args = {
  conversationMessage: {
    author: {name: 'Bob Barker'},
    recipients: [{name: 'Bob Barker'}, {name: 'Sally Ford'}],
    createdAt: 'November 5, 2020 at 2:25pm',
    body: 'This is the body text for the message.',
  },
}
