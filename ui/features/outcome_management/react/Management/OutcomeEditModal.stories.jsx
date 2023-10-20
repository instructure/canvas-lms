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

import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import React from 'react'
import OutcomeEditModal from './OutcomeEditModal'

export default {
  title: 'Examples/Outcomes/OutcomeEditModal',
  component: OutcomeEditModal,
  args: {
    outcome: {
      _id: '1',
      title: 'Outcome 1',
      description: 'Outcome description',
      displayName: 'Friendly outcome name',
      contextType: 'Account',
      contextId: '1',
    },
    isOpen: true,
    onCloseHandler: () => {},
  },
}

const withContext = (children, {contextType = 'Account', contextId = '1'} = {}) => (
  <OutcomesContext.Provider value={{env: {contextType, contextId}}}>
    {children}
  </OutcomesContext.Provider>
)

const Template = args => withContext(<OutcomeEditModal {...args} />)
export const Default = Template.bind({})

export const withNoName = Template.bind({})
withNoName.args = {
  outcome: {
    _id: '1',
    title: '',
    description: 'Outcome description',
    displayName: 'Friendly outcome name',
    contextType: 'Account',
    contextId: '1',
  },
}

export const withLongName = Template.bind({})
withLongName.args = {
  outcome: {
    _id: '1',
    title: 'A very long outcome name. '.repeat(10),
    description: 'Outcome description',
    displayName: 'Friendly outcome name',
    contextType: 'Account',
    contextId: '1',
  },
}

export const withLongDisplayName = Template.bind({})
withLongDisplayName.args = {
  outcome: {
    _id: '1',
    title: 'Outcome 1',
    description: 'Outcome description',
    displayName: 'Long friendly outcome name. '.repeat(10),
    contextType: 'Account',
    contextId: '1',
  },
}

export const withLongDescription = Template.bind({})
withLongDescription.args = {
  outcome: {
    _id: '1',
    title: 'Outcome 1',
    description: 'A very long outcome description. '.repeat(18),
    displayName: 'Friendly outcome name',
    contextType: 'Account',
    contextId: '1',
  },
}

export const withoutEditPermission = Template.bind({})
withoutEditPermission.args = {
  outcome: {
    _id: '1',
    title: 'Outcome 1',
    description: 'Outcome description',
    displayName: 'Friendly outcome name',
    contextType: 'Account',
    contextId: '2',
  },
}

export const withFriendlyDescription = Template.bind({})
withFriendlyDescription.args = {
  outcome: {
    _id: '1',
    title: 'Outcome 1',
    description: 'An outcome description.',
    friendlyDescription: 'A friendly outcome description.',
    displayName: 'Friendly outcome name',
  },
}
