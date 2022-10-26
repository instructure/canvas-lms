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
import AlignmentOutcomeItem from './AlignmentOutcomeItem'

export default {
  title: 'Examples/Outcomes/AlignmentOutcomeItem',
  component: AlignmentOutcomeItem,
  args: {
    title: 'Outcome Title',
    description: 'Outcome Description',
    alignmentCount: 15,
  },
}

const Template = args => <AlignmentOutcomeItem {...args} />

export const Default = Template.bind({})

export const withLongDescription = Template.bind({})
withLongDescription.args = {
  description: 'Long Outcome Description '.repeat(10),
}
