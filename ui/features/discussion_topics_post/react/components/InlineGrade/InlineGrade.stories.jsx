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
import {InlineGrade} from './InlineGrade'

export default {
  title: 'Examples/Discussion Posts/Components/InlineGrade',
  component: InlineGrade,
  argTypes: {onGradeChange: {action: 'Grade Change'}},
}

const Template = args => <InlineGrade {...args} />

export const NeedsGrading = Template.bind({})
NeedsGrading.args = {
  isGraded: false,
  pointsPossible: '100',
}

export const Loading = Template.bind({})
Loading.args = {
  currentGrade: '90',
  isLoading: true,
  isGraded: false,
  pointsPossible: '100',
}

export const Graded = Template.bind({})
Graded.args = {
  currentGrade: '90',
  isGraded: true,
  pointsPossible: '100',
}
