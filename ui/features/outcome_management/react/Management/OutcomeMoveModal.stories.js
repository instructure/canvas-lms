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
import OutcomeMoveModal from './OutcomeMoveModal'
import {MockedProvider} from '@apollo/react-testing'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {smallOutcomeTree, moveOutcomeMock} from '@canvas/outcomes/mocks/Management'
import {createCache} from '@canvas/apollo'

const outcomesGenerator = (startId, count, canUnlink = true, title = '') =>
  new Array(count).fill(0).reduce(
    (acc, _curr, idx) => ({
      ...acc,
      [`${startId + idx}`]: {
        _id: `${idx + 100}`,
        linkId: `${startId + idx}`,
        title: title || `Learning Outcome ${startId + idx}`,
        canUnlink,
      },
    }),
    {}
  )

export default {
  title: 'Examples/Outcomes/OutcomeMoveModal',
  component: OutcomeMoveModal,
  args: {
    isOpen: true,
    outcomes: outcomesGenerator(1, 2),
  },
  argTypes: {
    onCloseHandler: {action: 'closed'},
    onCleanupHandler: {action: 'cleanup'},
  },
}

const Template = args => (
  <OutcomesContext.Provider
    value={{env: {contextType: 'Account', contextId: '1', rootOutcomeGroup: {id: '100'}}}}
  >
    <MockedProvider mocks={[...smallOutcomeTree(), moveOutcomeMock()]} cache={createCache()}>
      <OutcomeMoveModal {...args} />
    </MockedProvider>
  </OutcomesContext.Provider>
)
export const Default = Template.bind({})

export const withOneOutcome = Template.bind({})
withOneOutcome.args = {
  outcomes: outcomesGenerator(1, 1),
}
