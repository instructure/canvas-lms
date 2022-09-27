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
import SubmissionStatus from './SubmissionStatus'

export default {
  title: 'Examples/Evaluate/Gradebook/SubmissionStatus',
  component: SubmissionStatus,
  args: {
    assignment: {
      anonymizeStudents: false,
      postManually: false,
      published: true,
    },
    isConcluded: false,
    isInClosedGradingPeriod: false,
    isInNoGradingPeriod: false,
    isInOtherGradingPeriod: false,
    isNotCountedForScore: false,
    submission: {
      drop: false,
      excused: false,
      hasPostableComments: false,
      postedAt: Date.now,
      score: 10,
      workflowState: 'graded',
    },
  },
}

const Template = args => <SubmissionStatus {...args} />

export const Default = Template.bind({})
export const Excused = Template.bind({})
export const Dropped = Template.bind({})
export const Hidden = Template.bind({})
export const Unpublished = Template.bind({})
export const Concluded = Template.bind({})
export const ClosedGradingPeriod = Template.bind({})
export const NoGradingPeriod = Template.bind({})
export const OtherGradingPeriod = Template.bind({})
export const NotCountedForScore = Template.bind({})

Excused.args = {
  submission: {
    excused: true,
    postedAt: Date.now,
  },
}

Dropped.args = {
  submission: {
    drop: true,
  },
}

Hidden.args = {
  submission: {
    hasPostableComments: false,
    postedAt: false,
    score: 10,
    workflowState: 'graded',
  },
}

Unpublished.args = {
  assignment: {
    published: false,
  },
}

Concluded.args = {
  isConcluded: true,
}

ClosedGradingPeriod.args = {
  isInClosedGradingPeriod: true,
}

NoGradingPeriod.args = {
  isInNoGradingPeriod: true,
}

OtherGradingPeriod.args = {
  isInOtherGradingPeriod: true,
}

NotCountedForScore.args = {
  isNotCountedForScore: true,
}
