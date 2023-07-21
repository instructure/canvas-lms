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
import {MockedProvider} from '@apollo/react-testing'
import FindOutcomesModal from './FindOutcomesModal'
import {createCache} from '@canvas/apollo'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {findModalMocks} from '@canvas/outcomes/mocks/Outcomes'

export default {
  title: 'Examples/Outcomes/FindOutcomesModal',
  component: FindOutcomesModal,
  args: {
    open: true,
    onCloseHandler: () => {},
    isCourse: false,
    includeGlobalRootGroup: false,
    isMobileView: false,
  },
  // Adding a story decorator will cause the component to re-render when a control change
  //  is presented. This is necessary becuase useEffect is only called once upon initial render
  //  and would otherwise not adjust the story when controls are modified
  decorators: [Story => <Story />],
}

const Template = args => {
  window.ENV = {}
  // we only show the global root group for the account context
  if (args.includeGlobalRootGroup && !args.isCourse) {
    window.ENV = {
      GLOBAL_ROOT_OUTCOME_GROUP_ID: '1',
    }
  }
  const response = findModalMocks(args)
  if (args.response) {
    // Overwrite the result data if it's provided
    response[0].result.data = args.response
  }
  return (
    <OutcomesContext.Provider
      value={{
        env: {
          contextType: args.isCourse ? 'Course' : 'Account',
          contextId: '1',
          isMobileView: args.isMobileView,
        },
      }}
    >
      <MockedProvider mocks={response} cache={createCache()}>
        <FindOutcomesModal {...args} />
      </MockedProvider>
    </OutcomesContext.Provider>
  )
}

export const Default = Template.bind({})

export const Query = Template.bind({})
Query.args = {
  // Allow control of only the result data
  response: findModalMocks()[0].result.data,
}

export const withTargetGroup = Template.bind({})
withTargetGroup.args = {
  targetGroup: {
    _id: '1',
    title: 'Group Name',
  },
}
