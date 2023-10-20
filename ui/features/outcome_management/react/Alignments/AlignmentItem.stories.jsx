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
import AlignmentItem from './AlignmentItem'

export default {
  title: 'Examples/Outcomes/AlignmentItem',
  component: AlignmentItem,
  args: {
    id: '1',
    type: 'Assignment',
    title: 'Assignment 1',
    url: '/courses/1/outcomes/1/alignments/3',
    moduleTitle: 'Module 1',
    moduleUrl: '/courses/1/modules/1',
  },
}

const Template = args => <AlignmentItem {...args} />

export const Default = Template.bind({})

export const withRubric = Template.bind({})
withRubric.args = {
  type: 'Rubric',
  title: 'Rubric 1',
}

export const withLongAlignmentTitle = Template.bind({})
withLongAlignmentTitle.args = {
  title: 'Long Alignment Title '.repeat(10),
}

export const withLongModuleTitle = Template.bind({})
withLongModuleTitle.args = {
  moduleTitle: 'Long Module Title '.repeat(10),
}

export const withoutModuleTitle = Template.bind({})
withoutModuleTitle.args = {
  moduleTitle: null,
}

export const withoutModuleUrl = Template.bind({})
withoutModuleUrl.args = {
  moduleUrl: null,
}
