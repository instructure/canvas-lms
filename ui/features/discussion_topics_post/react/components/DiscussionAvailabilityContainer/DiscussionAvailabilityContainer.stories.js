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

import React from 'react'
import {DiscussionAvailabilityContainer} from './DiscussionAvailabilityContainer'

export default {
  title: 'Examples/Discussion Posts/Components/DiscussionAvailabilityContainer',
  component: DiscussionAvailabilityContainer,
  argTypes: {},
}

const mockSections = [
  {
    id: 'U2VjdGlvbi00',
    _id: '1',
    userCount: 5,
    name: 'section 2',
  },
  {
    id: 'U2VjdGlvbi01',
    _id: '2',
    userCount: 1,
    name: 'section 3',
  },
]

const Template = args => <DiscussionAvailabilityContainer {...args} />

export const AllSections = Template.bind({})
AllSections.args = {
  courseSections: [],
  anonymousState: null,
  lockAt: null,
  delayedPostAt: null,
  totalUserCount: 5,
}

export const AllSectionsWithAvailabilityAnonymous = Template.bind({})
AllSectionsWithAvailabilityAnonymous.args = {
  courseSections: [],
  anonymousState: 'full_anonymity',
  lockAt: null,
  delayedPostAt: null,
  totalUserCount: 5,
}

export const AllSectionsWithPartiallyAnonymousAvailability = Template.bind({})
AllSectionsWithPartiallyAnonymousAvailability.args = {
  courseSections: [],
  anonymousState: 'partial_anonymity',
  lockAt: null,
  delayedPostAt: null,
  totalUserCount: 5,
}

export const TwoSections = Template.bind({})
TwoSections.args = {
  courseSections: mockSections,
  anonymousState: null,
  lockAt: null,
  delayedPostAt: null,
  totalUserCount: 5,
}
