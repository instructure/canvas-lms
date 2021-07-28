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

import React, {useReducer} from 'react'

import {View} from '@instructure/ui-view'

import {DEFAULT_SETTINGS} from '../../svg/constants'
import {PreviewSection} from './PreviewSection'
import {ShapeSection} from './ShapeSection'
import {ColorSection} from './ColorSection'
import {ImageSection} from './ImageSection'

export const CreateButtonForm = ({editor}) => {
  const [settings, dispatch] = useReducer(
    (state, changes) => ({...state, ...changes}),
    DEFAULT_SETTINGS
  )

  return (
    <View as="div">
      <PreviewSection settings={settings} />
      <ShapeSection settings={settings} onChange={dispatch} />
      <ColorSection settings={settings} onChange={dispatch} />
      <ImageSection editor={editor} settings={settings} onChange={dispatch} />
    </View>
  )
}
