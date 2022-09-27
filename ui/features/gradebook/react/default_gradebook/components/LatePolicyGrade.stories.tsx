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
import LatePolicyGrade from './LatePolicyGrade'

export default {
  title: 'Examples/Evaluate/Gradebook/LatePolicyGrade',
  component: LatePolicyGrade,
  args: {
    assignment: {
      pointsPossible: 100,
    },
    enterGradesAs: 'points',
    gradingScheme: [
      ['A', 90],
      ['B', 80],
      ['C', 70],
    ],
    submission: {
      grade: 'B',
      score: 85,
      pointsDeducted: 10,
    },
  },
}

const Template = args => <LatePolicyGrade {...args} />
export const Default = Template.bind({})
