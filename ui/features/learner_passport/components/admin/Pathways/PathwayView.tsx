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
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import type {PathwayDetailData, MilestoneData} from '../../types'
import PathwayTreeView from './PathwayTreeView'
import PathwayViewDetailsTray from './PathwayViewDetailsTray'
import MilestoneViewDetaislTray from './MilestoneViewDetailsTray'
import {showUnimplemented} from '../../shared/utils'

type PathwayViewProps = {
  pathway: PathwayDetailData
}

const PathwayView = ({pathway}: PathwayViewProps) => {
  const [zoomLevel, setZoomLevel] = useState(1)
  const [pathwayDetailsOpen, setPathwayDetailsOpen] = useState(false)
  const [activeMilestone, setActiveMilestone] = useState<MilestoneData | null>(null)
  const [milestoneDetailsOpen, setMilestoneDetailsOpen] = useState(false)

  const handleZoomIn = useCallback(() => {
    setZoomLevel(zoomLevel + 0.1)
  }, [zoomLevel])

  const handleZoomOut = useCallback(() => {
    setZoomLevel(zoomLevel - 0.1)
  }, [zoomLevel])

  const handleSelectFromTree = useCallback(
    (milestone: MilestoneData | null) => {
      if (milestone === null) {
        setActiveMilestone(null)
        setMilestoneDetailsOpen(false)
        setPathwayDetailsOpen(true)
      } else if (activeMilestone?.id === milestone.id) {
        setActiveMilestone(null)
        setMilestoneDetailsOpen(false)
      } else {
        setActiveMilestone(milestone as MilestoneData)
        setMilestoneDetailsOpen(true)
        setPathwayDetailsOpen(false)
      }
    },
    [activeMilestone]
  )

  const handleCloseMilestoneDetails = useCallback(() => {
    setMilestoneDetailsOpen(false)
    setActiveMilestone(null)
  }, [])

  const renderBuilderControls = useCallback(() => {
    return (
      <Flex as="div" justifyItems="space-between" margin="x-small">
        <Flex.Item>
          <Button renderIcon={IconZoomOutLine} onClick={handleZoomOut} />
          <Button renderIcon={IconZoomInLine} onClick={handleZoomIn} margin="0 0 0 x-small" />
        </Flex.Item>
        <Flex.Item>
          <Button onClick={showUnimplemented}>View as learner</Button>
        </Flex.Item>
      </Flex>
    )
  }, [handleZoomIn, handleZoomOut])

  return (
    <>
      <PathwayTreeView
        pathway={pathway}
        version="1"
        zoomLevel={zoomLevel}
        selectedStep={activeMilestone?.id || null}
        onSelected={handleSelectFromTree}
        renderTreeControls={renderBuilderControls}
      />
      <PathwayViewDetailsTray
        pathway={pathway}
        open={pathwayDetailsOpen}
        onClose={() => setPathwayDetailsOpen(false)}
      />
      <MilestoneViewDetaislTray
        milestone={activeMilestone}
        open={milestoneDetailsOpen}
        onClose={handleCloseMilestoneDetails}
      />
    </>
  )
}

export default PathwayView
