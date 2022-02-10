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

import React, {useState} from 'react'
import formatMessage from '../../../../../../format-message'
import {modes} from '../../../reducers/imageSection'

import {Button} from '@instructure/ui-buttons'
import {IconArrowOpenDownLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {Menu} from '@instructure/ui-menu'

const ModeSelect = ({dispatch}) => {
  const menuFor = mode => (
    <Menu.Item
      key={mode.type}
      value={mode.type}
      onSelect={() => {
        dispatch({type: mode.type})
      }}
    >
      {mode.label}
    </Menu.Item>
  )

  return (
    <Menu
      placement="bottom"
      trigger={
        <Button color="secondary" margin="small">
          {formatMessage('Add Image')}
          <View margin="none none none x-small">
            <IconArrowOpenDownLine />
          </View>
        </Button>
      }
    >
      {menuFor(modes.uploadImages)}
      {menuFor(modes.singleColorImages)}
      {menuFor(modes.multiColorImages)}
      {menuFor(modes.courseImages)}
    </Menu>
  )
}

export default ModeSelect
