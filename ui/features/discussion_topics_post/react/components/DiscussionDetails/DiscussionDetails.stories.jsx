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

// pass in an array of {string: text, bold: true, color: red}

import {DiscussionDetails} from './DiscussionDetails'

import React from 'react'
import {Assignment} from '../../../graphql/Assignment'

export default {
  title: 'Examples/Discussion Posts/Components/DiscussionDetails',
  component: DiscussionDetails,
  argTypes: {},
}

const Template = args => <DiscussionDetails {...args} />

export const SingleDueDate = Template.bind({})
SingleDueDate.args = {
  pointsPossible: 5,
  assignment: Assignment.mock(),
  isAdmin: true,
}

export const MultipleDueDates = Template.bind({})
MultipleDueDates.args = {
  assignmentOverrides: [
    {
      id: '1',
      dueAt: 'Sat, 29 May 2021 05:59:59 UTC +00:00',
      title: 'Mutants Group 1',
    },
    {
      id: '2',
      dueAt: 'Sun, 30 May 2021 05:59:59 UTC +00:00',
      title: 'Mutants Group 2',
      unlockAt: 'Fri, 28 May 2021 05:59:59 UTC +00:00',
      lockAt: 'Tue, 1 June 2021 05:59:59 UTC +00:00',
    },
    {
      id: '3',
      dueAt: 'Mon, 31 May 2021 05:59:59 UTC +00:00',
      title: 'Mutants Group 3',
    },
  ],
  canSeeMultipleDueDates: true,
  pointsPossible: 5,
  dueAtDisplayText: 'Jan 26 11:49pm',
}
