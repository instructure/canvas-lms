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

import React, {useCallback, useState} from 'react'
import {IconZoomInLine, IconZoomOutLine} from '@instructure/ui-icons'
import {Button} from '@instructure/ui-buttons'
import type {PathwayDetailData} from '../../types'
import PathwayTreeView from './PathwayTreeView'
import {showUnimplemented} from '../../shared/utils'

type PathwayViewProps = {
  pathway: PathwayDetailData
}

const PathwayView = ({pathway}: PathwayViewProps) => {
  const [zoomLevel, setZoomLevel] = useState(1)

  const handleZoomIn = useCallback(() => {
    setZoomLevel(zoomLevel + 0.1)
  }, [zoomLevel])

  const handleZoomOut = useCallback(() => {
    setZoomLevel(zoomLevel - 0.1)
  }, [zoomLevel])

  return (
    <div style={{position: 'relative'}}>
      <div style={{position: 'absolute', top: '.5rem', left: '.5rem', zIndex: 1}}>
        <Button renderIcon={IconZoomOutLine} onClick={handleZoomOut} />
        <Button renderIcon={IconZoomInLine} onClick={handleZoomIn} margin="0 0 0 x-small" />
      </div>
      <div style={{position: 'absolute', top: '.5rem', right: '.5rem', zIndex: 1}}>
        <Button onClick={showUnimplemented}>View as learner</Button>
      </div>

      <PathwayTreeView pathway={pathway} zoomLevel={zoomLevel} selectedStep={null} />
    </div>
  )
}

export default PathwayView
