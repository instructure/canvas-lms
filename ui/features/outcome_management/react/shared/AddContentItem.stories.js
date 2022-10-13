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
import AddContentItem from './AddContentItem'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'

export default {
  title: 'Examples/Outcomes/AddContentItem',
  component: AddContentItem,
  contextType: 'Account',
  contextId: '1',
  args: {
    parentGroupId: '1',
    labelInstructions: 'Add New Group',
    titleInstructions: 'Enter new group name',
    showIcon: true,
    onSaveHandler: () => {},
  },
}

const Template = args => {
  return (
    <OutcomesContext.Provider value={{env: {contextType: 'Account', contextId: '1'}}}>
      <AddContentItem {...args} />
    </OutcomesContext.Provider>
  )
}
export const Default = Template.bind({})
