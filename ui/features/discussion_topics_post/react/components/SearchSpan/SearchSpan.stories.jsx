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

import {SearchSpan} from './SearchSpan'

export default {
  title: 'Examples/Discussion Posts/Components/SearchSpan',
  component: SearchSpan,
  argTypes: {},
}

const Template = props => (
  <SearchSpan text="A message Posty Postersen" searchTerm="Posty" {...props} />
)

export const Default = Template.bind({})
Default.args = {}

export const MultipleInstances = Template.bind({})
MultipleInstances.args = {
  text: 'A posty message for Posty Postersen',
}

export const NoMatches = Template.bind({})
NoMatches.args = {
  text: 'This is the post that never ends. It goes on and on my friends. ',
}
