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
import GroupSelectionDrillDown from './GroupSelectionDrillDown'

const collectionsExample = {
  1: {
    id: 1,
    name: 'Root Group',
    collections: [2, 3],
    parentGroupId: 0,
  },
  2: {
    id: 2,
    name: 'Group 2',
    collections: [4],
    parentGroupId: 1,
  },
  3: {
    id: 3,
    name: 'Group 3',
    collections: [],
    parentGroupId: 1,
  },
}

export default {
  title: 'Examples/Outcomes/GroupSelectionDrillDown',
  component: GroupSelectionDrillDown,
  args: {
    collections: collectionsExample,
    rootId: 1,
  },
}

const Template = args => <GroupSelectionDrillDown {...args} />
export const Default = Template.bind({})
