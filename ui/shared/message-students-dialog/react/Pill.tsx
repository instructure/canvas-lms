/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {Tag} from '@instructure/ui-tag'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {IconAddSolid, IconXSolid} from '@instructure/ui-icons'
import {ApplyTheme} from '@instructure/ui-themeable'

const themeOverride = {
  [Tag.theme]: {
    defaultBackground: 'white'
  }
}

const Pill = ({studentId, observerId = null, text, onClick, selected = false}) => {
  const contents = selected ? (
    <>
      <View margin="0 small 0 0">
        <Text color="primary">{text}</Text>
      </View>
      <IconXSolid data-testid="item-selected" />
    </>
  ) : (
    <>
      <View margin="0 small 0 0">
        <Text color="secondary">{text}</Text>
      </View>
      <IconAddSolid data-testid="item-unselected" color="brand" />
    </>
  )

  return (
    <ApplyTheme theme={themeOverride}>
      <Tag text={contents} onClick={() => onClick(studentId, observerId)} />
    </ApplyTheme>
  )
}

export default Pill
