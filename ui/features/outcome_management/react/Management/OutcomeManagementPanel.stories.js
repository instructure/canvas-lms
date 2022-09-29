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
import OutcomeManagementPanel from '.'
import {createCache} from '@canvas/apollo'
import {accountMocks, smallOutcomeTree} from '@canvas/outcomes/mocks/Management'
import {MockedProvider} from '@apollo/react-testing'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'

export default {
  title: 'Examples/Outcomes/OutcomeManagementPanel',
  component: OutcomeManagementPanel,
  args: {
    contextType: 'Account',
    contextId: '1',
  },
  // Adding a story decorator will cause the component to re-render when a control change
  //  is presented. This is necessary becuase useEffect is only called once upon initial render
  //  and would otherwise not adjust the story when controls are modified
  decorators: [Story => <Story />],
}

const Template = args => {
  const response = smallOutcomeTree()
  if (args.response) {
    // Overwrite the result data if it's provided
    response[0].result.data = args.response
  }
  return (
    <OutcomesContext.Provider value={{env: {contextType: 'Account', contextId: '1'}}}>
      <MockedProvider mocks={response} cache={createCache()}>
        <OutcomeManagementPanel />
      </MockedProvider>
    </OutcomesContext.Provider>
  )
}

export const Default = Template.bind({})
Default.args = {
  queryOptions: {childGroupsCount: 1},
}

export const Query = Template.bind({})
Query.args = {
  // Allow control of only the result data
  response: accountMocks({childGroupsCount: 1})[0].result.data,
}
