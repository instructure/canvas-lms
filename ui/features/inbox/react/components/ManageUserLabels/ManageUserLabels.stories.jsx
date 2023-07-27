/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {ManageUserLabels} from './ManageUserLabels'

export default {
  title: 'Examples/Canvas Inbox/ManageUserLabels',
  component: ManageUserLabels,
  argTypes: {
    onCreate: {action: 'onCreate'},
    onDelete: {action: 'onDelete'},
    onClose: {action: 'onClose'},
  },
}

const Template = args => <ManageUserLabels {...args} />

export const OpenManageUserLabels = Template.bind({})
OpenManageUserLabels.args = {
  open: true,
  labels: ['Important', 'Assignment Info'],
}
