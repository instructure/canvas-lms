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
import GroupMoveModal from './GroupMoveModal'
import {MockedProvider} from '@apollo/react-testing'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {smallOutcomeTree} from '@canvas/outcomes/mocks/Management'
import {createCache} from '@canvas/apollo'

export default {
  title: 'Examples/Outcomes/GroupMoveModal',
  component: GroupMoveModal,
  args: {
    isOpen: true,
    groupId: '100',
    groupTitle: 'Outcome Group 1',
    parentGroup: {
      id: '0',
      title: 'Root Outcome Group',
    },
  },
  argTypes: {
    onCloseHandler: {action: 'closed'},
  },
}

const Template = args => {
  return (
    <OutcomesContext.Provider
      value={{env: {contextType: 'Account', contextId: '1', rootOutcomeGroup: {id: '0'}}}}
    >
      <MockedProvider mocks={smallOutcomeTree()} cache={createCache()}>
        <GroupMoveModal {...args} />
      </MockedProvider>
    </OutcomesContext.Provider>
  )
}
export const Default = Template.bind({})

export const withLongGroupTitle = Template.bind({})
withLongGroupTitle.args = {
  groupId: '100',
  groupTitle: 'This is a long group title. '.repeat(4),
}
