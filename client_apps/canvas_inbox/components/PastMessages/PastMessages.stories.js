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
import {PastMessages} from './PastMessages'

export default {
  title: 'Playground/Past Messages',
  component: PastMessages
}

const Template = args => <PastMessages {...args} />

export const Component = Template.bind({})
Component.args = {
  messages: [
    {
      name: 'Rick Sanchez',
      messageBody:
        "I don't do magic Morty, I do science. One takes brains, the other takes dark eye liner",
      date: 'November 5, 2020 at 11:03am'
    },
    {
      name: 'Morty Smith',
      messageBody: 'Is this the first part of some kind of magic trick?',
      date: 'November 5, 2020 at 11:02am'
    }
  ]
}
