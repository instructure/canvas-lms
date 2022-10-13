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
import {View} from '@instructure/ui-view'
import FindOutcomesView from './FindOutcomesView'

// Define default props for all stories
export default {
  title: 'Examples/Outcomes/FindOutcomesView',
  component: FindOutcomesView,
  args: {
    collection: {
      name: 'State Standards',
      isRootGroup: true,
      id: '1',
    },
    outcomeGroup: {
      contextId: '1',
      contextType: 'Account',
      outcomes: {
        edges: [
          {
            node: {
              _id: '11',
              title: 'Outcome 1',
              description: 'Outcome 1 description',
              isImported: false,
            },
          },
        ],
        pageInfo: {
          endCursor: 'abc',
          hasNextPage: true,
        },
      },
    },
    searchString: '',
    onChangeHandler: () => {},
    onClearHandler: () => {},
    onAddAllHandler: () => {},
  },
}

const Template = args => (
  <View as="div" height="95vh">
    <FindOutcomesView {...args} />
  </View>
)

export const Default = Template.bind({})

export const withLongGroupName = Template.bind({})
withLongGroupName.args = {
  collection: {
    name: 'This is a very long group name '.repeat(5),
    outcomesCount: 5,
  },
}

export const withLongSearch = Template.bind({})
withLongSearch.args = {
  searchString: 'This is a very long search '.repeat(7),
}

export const withSpaceSeparatedGroupName = Template.bind({})
withSpaceSeparatedGroupName.args = {
  collection: {
    name: 'CCSS ​Math ​Content ​2 ​MD ​A​1 '.repeat(3),
    outcomesCount: 6,
  },
}

export const withDotSeparatedGroupName = Template.bind({})
withDotSeparatedGroupName.args = {
  collection: {
    name: 'CCSS.​Math.​Content.​2.​MD.​A.​1.'.repeat(3),
    outcomesCount: 7,
  },
}

export const withMissingGroupName = Template.bind({})
withMissingGroupName.args = {
  collection: {
    name: '',
  },
}

export const withLargeNumberOfOutcomes = Template.bind({})
withLargeNumberOfOutcomes.args = {
  collection: {
    outcomesCount: 1234567890,
  },
}

export const withMissingNumberOfOutcomes = Template.bind({})
withMissingNumberOfOutcomes.args = {
  collection: {
    outcomesCount: null,
  },
}
