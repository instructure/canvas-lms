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
import {Button} from '@instructure/ui-buttons'
import {IconZoomOutLine, IconZoomInLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import type {DraftPathway, MilestoneData} from '../../../types'
import PathwayTreeView from '../PathwayTreeView'

const getLayout = (viewDirection: 'horizontal' | 'vertical', flipped: boolean) => {
  if (viewDirection === 'horizontal') {
    return flipped ? 'RL' : 'LR'
  } else {
    return flipped ? 'BT' : 'TB'
  }
}

type PathwayBuilderTreeProps = {
  pathway: DraftPathway
  selectedStep: string | null
  treeVersion: number
  onShowSidebar?: () => void
  onSelectStep?: (step: MilestoneData | null) => void
}

const PathwayBuilderTree = ({
  pathway,
  selectedStep,
  treeVersion,
  onShowSidebar,
  onSelectStep,
}: PathwayBuilderTreeProps) => {
  const [zoomLevel, setZoomLevel] = useState(1)
  const [viewDirection, setViewDirection] = useState<'horizontal' | 'vertical'>('vertical')
  const [flipped, setFlipped] = useState(false)

  const handleZoomIn = useCallback(() => {
    setZoomLevel(zoomLevel + 0.1)
  }, [zoomLevel])

  const handleZoomOut = useCallback(() => {
    setZoomLevel(zoomLevel - 0.1)
  }, [zoomLevel])

  const handleViewDirectionClick = useCallback(() => {
    if (viewDirection === 'horizontal') {
      setViewDirection('vertical')
    } else {
      setViewDirection('horizontal')
    }
  }, [viewDirection])

  const handleFlipClick = useCallback(() => {
    setFlipped(!flipped)
  }, [flipped])

  const renderBuilderControls = useCallback(() => {
    return (
      <Flex as="div" justifyItems="space-between" margin="x-small">
        <Flex.Item>
          {onShowSidebar ? (
            <Button onClick={onShowSidebar} margin="0 x-small 0 0">
              Pathway builder
            </Button>
          ) : null}
          <Button renderIcon={IconZoomOutLine} onClick={handleZoomOut} margin="0 x-small 0 0" />
          <Button renderIcon={IconZoomInLine} onClick={handleZoomIn} />
        </Flex.Item>
        <Flex.Item>
          <Button onClick={handleViewDirectionClick} margin="0 x-small 0 0">
            {viewDirection === 'vertical' ? 'View horizontally' : 'View vertically'}
          </Button>
          <Button onClick={handleFlipClick}>Flip pathway</Button>
        </Flex.Item>
      </Flex>
    )
  }, [
    handleFlipClick,
    handleViewDirectionClick,
    handleZoomIn,
    handleZoomOut,
    onShowSidebar,
    viewDirection,
  ])

  const layout = getLayout(viewDirection, flipped)
  return (
    <PathwayTreeView
      version={`${treeVersion}-${layout}`}
      pathway={pathway}
      selectedStep={selectedStep}
      zoomLevel={zoomLevel}
      layout={layout}
      onSelected={onSelectStep}
      renderTreeControls={renderBuilderControls}
    />
  )
}

export default PathwayBuilderTree
