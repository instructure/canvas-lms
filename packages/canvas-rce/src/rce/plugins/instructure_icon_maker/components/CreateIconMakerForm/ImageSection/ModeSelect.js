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

import React, {forwardRef} from 'react'
import formatMessage from '../../../../../../format-message'
import {modes, actions} from '../../../reducers/imageSection'
import {ICON_MAKER_ADD_IMAGE_MENU_ID} from '../../../utils/IconMakerClose'

import {Button} from '@instructure/ui-buttons'
import {IconArrowOpenDownLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {Menu} from '@instructure/ui-menu'

const ModeSelect = forwardRef(({dispatch, mountNode, onFocus, onBlur, rcsConfig}, ref) => {
  const menuFor = mode => (
    <Menu.Item
      key={mode.type}
      value={mode.type}
      id={mode.type}
      onSelect={() => {
        dispatch({type: mode.type})
        dispatch({...actions.SET_IMAGE_COLLECTION_OPEN, payload: true})
      }}
    >
      {mode.label}
    </Menu.Item>
  )

  const showNonIconImages = !!rcsConfig?.features?.icon_maker_cropper

  return (
    <Menu
      mountNode={mountNode}
      placement="bottom"
      ref={ref}
      onFocus={onFocus}
      onBlur={onBlur}
      // maps to data-position-content
      id={ICON_MAKER_ADD_IMAGE_MENU_ID}
      trigger={
        <Button color="secondary" data-testid="add-image">
          {formatMessage('Add Image')}
          <View margin="none none none x-small">
            <IconArrowOpenDownLine />
          </View>
        </Button>
      }
    >
      {showNonIconImages && menuFor(modes.uploadImages)}
      {menuFor(modes.singleColorImages)}
      {menuFor(modes.multiColorImages)}
      {showNonIconImages && menuFor(modes.courseImages)}
    </Menu>
  )
})

export default ModeSelect
