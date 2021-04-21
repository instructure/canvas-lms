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
import MoveModal from './MoveModal'
import {MockedProvider} from '@apollo/react-testing'
import OutcomesContext from '../contexts/OutcomesContext'
import {smallOutcomeTree} from './__tests__/mocks'
import {createCache} from 'jsx/canvas-apollo'

export default {
  title: 'Examples/Outcomes/MoveModal',
  component: MoveModal,
  args: {
    isOpen: true,
    title: 'Group Title',
    type: 'group',
    contextId: 1,
    contextType: 'Account',
    groupId: '101',
    parentGroupId: 100
  },
  argTypes: {
    onCloseHandler: {action: 'closed'},
    onMoveHandler: {action: 'moved'}
  }
}

const Template = args => {
  return (
    <OutcomesContext.Provider value={{env: {contextType: 'Account', contextId: '1'}}}>
      <MockedProvider mocks={smallOutcomeTree()} cache={createCache()}>
        <MoveModal {...args} />
      </MockedProvider>
    </OutcomesContext.Provider>
  )
}
export const Default = Template.bind({})

export const veryLongOutcomeTitle = Template.bind({})
veryLongOutcomeTitle.args = {
  title: 'This is a very long title.'.repeat(10)
}

export const showsMoveGroupHeader = Template.bind({})
showsMoveGroupHeader.args = {
  type: 'group'
}
