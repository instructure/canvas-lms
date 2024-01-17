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
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import type {PathwayDetailData, MilestoneData} from '../../../types'
import PathwayBuilderSidebar from './PathwayBuilderSidebar'
import PathwayBuilderTree from './PathwayBuilderTree'
import MilestoneTray from './MilestoneTray'

type PathwayBuilderProps = {
  pathway: PathwayDetailData
  onChange: (newValues: Partial<PathwayDetailData>) => void
}

const PathwayBuilder = ({pathway, onChange}: PathwayBuilderProps) => {
  const [currentRoot, setCurrentRoot] = useState<MilestoneData | null>(null)
  const [milestoneTrayOpen, setMilestoneTrayOpen] = useState(false)
  const [milestoneTrayOpenCount, setMilestoneTrayOpenCount] = useState(0)
  const [treeVersion, setTreeVersion] = useState(0)
  const [sidebarIsVisible, setSidebarIsVisible] = useState(true)

  const handleShowSidebar = useCallback(() => {
    setSidebarIsVisible(true)
    setTreeVersion(Date.now())
  }, [])

  const handleHideSidebar = useCallback(() => {
    setSidebarIsVisible(false)
  }, [])

  const handleAddMilestone = useCallback(() => {
    setMilestoneTrayOpenCount(milestoneTrayOpenCount + 1)
    setMilestoneTrayOpen(true)
  }, [milestoneTrayOpenCount])

  const handleSaveMilestone = useCallback(
    (newMilestone: MilestoneData) => {
      setTreeVersion(Date.now())
      setMilestoneTrayOpen(false)
      const first_milestones = [...pathway.first_milestones]
      const milestones = [...pathway.milestones]
      if (currentRoot === null) {
        first_milestones.push(newMilestone.id)
      } else {
        const rootMilestone = {...currentRoot}
        if (rootMilestone) {
          rootMilestone.next_milestones.push(newMilestone.id)
        }
      }
      onChange({first_milestones, milestones: [...milestones, newMilestone]})
    },
    [currentRoot, onChange, pathway.first_milestones, pathway.milestones]
  )

  const handleSelectStepFromTree = useCallback(
    (step: MilestoneData | null) => {
      if (step) {
        setCurrentRoot(step)
      } else {
        setCurrentRoot(null)
      }
    },
    [setCurrentRoot]
  )

  return (
    <View as="div">
      <Flex as="div" alignItems="stretch" height="100%">
        {sidebarIsVisible ? (
          <Flex.Item shouldShrink={false} shouldGrow={false}>
            <PathwayBuilderSidebar
              pathway={pathway}
              currentStep={currentRoot}
              onAddStep={handleAddMilestone}
              onHideSidebar={handleHideSidebar}
            />
          </Flex.Item>
        ) : null}

        <Flex.Item shouldGrow={true} shouldShrink={true}>
          <PathwayBuilderTree
            pathway={pathway}
            selectedStep={currentRoot ? currentRoot.id : null}
            onShowSidebar={sidebarIsVisible ? undefined : handleShowSidebar}
            onSelectStep={handleSelectStepFromTree}
            treeVersion={treeVersion}
          />
        </Flex.Item>
      </Flex>
      <MilestoneTray
        key={milestoneTrayOpenCount}
        open={milestoneTrayOpen}
        variant="add"
        onClose={() => setMilestoneTrayOpen(false)}
        onSave={handleSaveMilestone}
      />
    </View>
  )
}

export default PathwayBuilder
