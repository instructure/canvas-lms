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
import ManageOutcomeItem from './ManageOutcomeItem'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'

export default {
  title: 'Examples/Outcomes/ManageOutcomeItem',
  component: ManageOutcomeItem,
  args: {
    id: '1',
    title: 'Outcome',
    description: 'Outcome Description',
    isFirst: false,
    isChecked: false,
    canManageOutcome: true,
    canUnlink: true,
    parentGroupId: '100',
    parentGroupTitle: 'Outcome Group',
    outcomeContextType: 'Account',
    outcomeContextId: '1',
    onMenuHandler: () => {},
    onCheckboxHandler: () => {},
  },
}

const Template = args => {
  return withContext(<ManageOutcomeItem {...args} />)
}

const withContext = (children, {contextType = 'Account', contextId = '1'} = {}) => (
  <OutcomesContext.Provider value={{env: {contextType, contextId}}}>
    {children}
  </OutcomesContext.Provider>
)

export const Default = Template.bind({})

export const withoutManagePermission = Template.bind({})
withoutManagePermission.args = {
  canManageOutcome: false,
}

export const withoutDestroyPermission = Template.bind({})
withoutDestroyPermission.args = {
  canUnlink: false,
}

export const withoutEditPermission = Template.bind({})
withoutEditPermission.args = {
  outcomeContextId: 2,
}
