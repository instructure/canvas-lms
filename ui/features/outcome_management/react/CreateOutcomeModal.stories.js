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
import {createCache} from '@canvas/apollo'
import CreateOutcomeModal from './CreateOutcomeModal'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {smallOutcomeTree} from '@canvas/outcomes/mocks/Management'

export default {
  title: 'Examples/Outcomes/CreateOutcomeModal',
  component: CreateOutcomeModal,
  args: {
    isOpen: true,
    onCloseHandler: () => {}
  }
}

const Template = args => {
  return (
    <OutcomesContext.Provider
      value={{env: {contextType: 'Account', contextId: '1', friendlyDescriptionFF: true}}}
    >
      <MockedProvider cache={createCache()} mocks={smallOutcomeTree('Account')}>
        <CreateOutcomeModal {...args} />
      </MockedProvider>
    </OutcomesContext.Provider>
  )
}
export const Default = Template.bind({})
