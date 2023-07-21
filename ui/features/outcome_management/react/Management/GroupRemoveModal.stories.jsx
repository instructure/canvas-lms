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
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import GroupRemoveModal from './GroupRemoveModal'

export default {
  title: 'Examples/Outcomes/GroupRemoveModal',
  component: GroupRemoveModal,
  args: {
    groupId: '1',
    groupTitle: 'State Standards',
    isOpen: true,
    onCloseHandler: () => {},
  },
}

const withContext = (children, {contextType = 'Account', contextId = '1'} = {}) => (
  <OutcomesContext.Provider value={{env: {contextType, contextId}}}>
    {children}
  </OutcomesContext.Provider>
)

const Template = args => {
  return withContext(<GroupRemoveModal {...args} />)
}

export const Default = Template.bind({})

const TemplateAlt = args => {
  return withContext(<GroupRemoveModal {...args} />, {
    contextType: 'Course',
  })
}

export const inCourseContext = TemplateAlt.bind({})
