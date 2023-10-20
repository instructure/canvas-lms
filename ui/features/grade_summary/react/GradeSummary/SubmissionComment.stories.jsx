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

import SubmissionComment from './SubmissionComment'
import React from 'react'

export default {
  title: 'Examples/Student Grade Summary/SubmissionComment',
  component: SubmissionComment,
}

const defaultComment = {
  comment:
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus tempor nunc non arcu placerat, at mollis massa suscipit. Nullam tincidunt bibendum turpis vitae consectetur. Proin posuere placerat elit, id mollis erat blandit porta. Aliquam laoreet dui sit amet ultricies pharetra. Aliquam euismod, ex at faucibus viverra, mauris velit ullamcorper massa, ut ultricies orci orci eu lorem. Pellentesque quis lectus nisl. Suspendisse sem dolor, facilisis eu velit et, varius tempus massa. Sed luctus imperdiet metus at tempor. Suspendisse tincidunt neque eu velit luctus gravida. Suspendisse sed aliquet nisi. Curabitur sagittis consequat euismod. Cras aliquam nulla vel dolor semper placerat. Nunc in dolor enim.',
  createdAt: '2022-04-19T10:32:29-06:00',
  author: {
    name: 'Ron Weasley',
    shortName: 'Ron Weasley',
    __typename: 'User',
  },
  __typename: 'SubmissionComment',
}

const Template = args => <SubmissionComment {...args} />

export const Default = Template.bind({})
Default.args = {
  comment: defaultComment,
  key: '1',
}
