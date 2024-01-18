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

import React, {useCallback, useEffect, useState} from 'react'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import type {PathwayDetailData, DraftPathway, MilestoneData} from '../../../types'
import PathwayBuilderSidebar from './PathwayBuilderSidebar'
import PathwayBuilderTree from './PathwayBuilderTree'
import MilestoneTray from './MilestoneTray'
import {showUnimplemented} from '../../../shared/utils'

type PathwayBuilderProps = {
  pathway: DraftPathway
  onChange: (newValues: Partial<PathwayDetailData>) => void
}

const PathwayBuilder = ({pathway, onChange}: PathwayBuilderProps) => {
  const [currentRoot, setCurrentRoot] = useState<MilestoneData | null>(null)
  const [milestoneTrayOpen, setMilestoneTrayOpen] = useState(false)
  const [milestoneTrayOpenKey, setMilestoneTrayOpenKey] = useState(0)
  const [activeMilestone, setActiveMilestone] = useState<MilestoneData | undefined>(undefined)
  const [sidebarIsVisible, setSidebarIsVisible] = useState(true)

  const handleShowSidebar = useCallback(() => {
    setSidebarIsVisible(true)
  }, [])

  const handleHideSidebar = useCallback(() => {
    setSidebarIsVisible(false)
  }, [])

  const handleAddMilestone = useCallback(() => {
    setMilestoneTrayOpenKey(Date.now())
    setMilestoneTrayOpen(true)
  }, [])

  const handleEditPathway = useCallback(() => {
    showUnimplemented({currentTarget: {textContent: 'edit pathway'}})
  }, [])

  const handleEditMilestone = useCallback(
    (milestoneId: string) => {
      setMilestoneTrayOpenKey(Date.now())
      const milestone = pathway.milestones.find(m => m.id === milestoneId)
      setActiveMilestone(milestone)
      setMilestoneTrayOpen(true)
    },
    [pathway.milestones]
  )

  const handleDeleteMilestone = useCallback(
    (milestoneID: string) => {
      const newMilestones = [...pathway.milestones]
      const mIndex = pathway.milestones.findIndex(m => m.id === milestoneID)
      if (mIndex >= 0) {
        newMilestones.splice(mIndex, 1)
      }

      const newFirstMilestones = [...pathway.first_milestones]
      const fIndex = pathway.first_milestones.findIndex(m => m === milestoneID)
      if (fIndex >= 0) {
        newFirstMilestones.splice(fIndex, 1)
      }
      onChange({milestones: newMilestones, first_milestones: newFirstMilestones})
    },
    [onChange, pathway.first_milestones, pathway.milestones]
  )

  const handleSaveMilestone = useCallback(
    (newMilestone: MilestoneData) => {
      setMilestoneTrayOpen(false)

      const mIndex = pathway.milestones.findIndex(m => m.id === newMilestone.id)
      if (mIndex >= 0) {
        const newMilestones = [...pathway.milestones]
        newMilestones[mIndex] = newMilestone
        onChange({milestones: newMilestones})
      } else {
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
      }
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
              onEditPathway={handleEditPathway}
              onEditStep={handleEditMilestone}
              onDeleteStep={handleDeleteMilestone}
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
            treeVersion={pathway.timestamp}
          />
        </Flex.Item>
      </Flex>
      <MilestoneTray
        key={milestoneTrayOpenKey}
        milestone={activeMilestone}
        open={milestoneTrayOpen}
        variant="add"
        onClose={() => setMilestoneTrayOpen(false)}
        onSave={handleSaveMilestone}
      />
    </View>
  )
}

export default PathwayBuilder
