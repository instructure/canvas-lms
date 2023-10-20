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
import MessageStudentsWhoDialog from './MessageStudentsWhoDialog'
import {ApolloProvider} from 'react-apollo'
import {createClient} from '@canvas/apollo'

const students = [
  {
    id: '100',
    name: 'Adam Jones',
    sortableName: 'Jones, Adam',
  },
  {
    id: '101',
    name: 'Betty Ford',
    sortableName: 'Ford, Betty',
  },
  {
    id: '102',
    name: 'Charlie Xi',
    sortableName: 'Xi, Charlie',
  },
  {
    id: '103',
    name: 'Dana Smith',
    sortableName: 'Smith, Dana',
  },
]

export default {
  title: 'Examples/Evaluate/Shared/MessageStudentsWhoDialog',
  component: MessageStudentsWhoDialog,
  args: {
    assignment: {
      gradingType: 'points',
      id: '100',
      name: 'Some assignment',
      nonDigitalSubmission: false,
    },
    userId: '123',
    students,
  },
  argTypes: {
    onClose: {action: 'closed'},
  },
}

const Template = args => (
  <ApolloProvider client={createClient()}>
    <MessageStudentsWhoDialog {...args} />
  </ApolloProvider>
)
export const ScoredAssignment = Template.bind({})
ScoredAssignment.args = {
  assignment: {
    gradingType: 'points',
    id: '100',
    name: 'A pointed assignment',
    nonDigitalSubmission: false,
  },
  students,
}

export const UngradedAssignment = Template.bind({})
UngradedAssignment.args = {
  assignment: {
    gradingType: 'not_graded',
    id: '200',
    name: 'A pointless assignment',
    nonDigitalSubmission: false,
  },
  students,
}

export const PassFailAssignment = Template.bind({})
PassFailAssignment.args = {
  assignment: {
    gradingType: 'pass_fail',
    id: '300',
    name: 'A pass-fail assignment',
    nonDigitalSubmission: false,
  },
  students,
}

export const UnsubmittableAssignment = Template.bind({})
UnsubmittableAssignment.args = {
  assignment: {
    gradingType: 'no_submission',
    id: '400',
    name: 'An unsubmittable assignment',
    nonDigitalSubmission: true,
  },
  students,
}
