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
import {Flex} from '@instructure/ui-flex'
import {actions} from '../reducers/imageCropper'
import {ZoomControls} from './ZoomControls'
import {RotationControls} from './RotationControls'
import {ShapeControls} from './ShapeControls'
import {ResetControls} from './ResetControls'

export const Controls = ({settings, dispatch}) => {
  return (
    <Flex
      id="imageCropperControls"
      direction="row"
      margin="x-small"
      alignItems="start"
      role="group"
    >
      <ShapeControls
        shape={settings.shape}
        onChange={shape => dispatch({type: actions.SET_SHAPE, payload: shape})}
      />
      <RotationControls
        rotation={settings.rotation}
        onChange={rotation => dispatch({type: actions.SET_ROTATION, payload: rotation})}
      />
      <ZoomControls
        scaleRatio={settings.scaleRatio}
        onChange={scaleRatio => dispatch({type: actions.SET_SCALE_RATIO, payload: scaleRatio})}
      />
      <Flex.Item shouldGrow={true} />
      <ResetControls onReset={() => dispatch({type: actions.RESET_SETTINGS})} />
    </Flex>
  )
}
