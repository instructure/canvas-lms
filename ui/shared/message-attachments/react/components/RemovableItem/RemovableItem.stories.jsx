/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {RemovableItem} from './RemovableItem'

export default {
  title: 'Examples/Canvas Inbox/RemovableItem',
  component: RemovableItem,
  argTypes: {
    onRemove: {action: 'Remove'},
  },
}

const Template = args => <RemovableItem {...args} />

export const Default = Template.bind({})
Default.args = {
  screenReaderLabel: 'Remove me!',
  children: <div style={{width: '80px', height: '80px', background: 'grey'}} />,
}
