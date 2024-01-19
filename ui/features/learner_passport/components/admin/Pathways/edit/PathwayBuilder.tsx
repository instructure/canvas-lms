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
import type {
  LearnerGroupType,
  PathwayBadgeType,
  PathwayDetailData,
  DraftPathway,
  MilestoneData,
} from '../../../types'
import PathwayBuilderSidebar from './PathwayBuilderSidebar'
import PathwayBuilderTree from './PathwayBuilderTree'
import MilestoneTray from './MilestoneTray'
import PathwayDetailsTray from './PathwayDetailsTray'
import confirm from '../../../shared/Confirmation'

type PathwayBuilderProps = {
  pathway: DraftPathway
  mode: 'create' | 'edit'
  allBadges: PathwayBadgeType[]
  allLearnerGroups: LearnerGroupType[]
  onChange: (newValues: Partial<PathwayDetailData>) => void
}

const PathwayBuilder = ({
  pathway,
  mode,
  allBadges,
  allLearnerGroups,
  onChange,
}: PathwayBuilderProps) => {
  const [currentRoot, setCurrentRoot] = useState<MilestoneData | null>(null)
  const [sidebarIsVisible, setSidebarIsVisible] = useState(true)
  const [milestoneTrayOpenKey, setMilestoneTrayOpenKey] = useState(0)
  const [activeMilestone, setActiveMilestone] = useState<MilestoneData | undefined>(undefined)
  const [pathwayTrayOpenKey, setPathwayTrayOpenKey] = useState(mode === 'create' ? Date.now() : 0)

  const handleShowSidebar = useCallback(() => {
    setSidebarIsVisible(true)
  }, [])

  const handleHideSidebar = useCallback(() => {
    setSidebarIsVisible(false)
  }, [])

  const handleAddMilestone = useCallback(() => {
    setMilestoneTrayOpenKey(Date.now())
  }, [])

  const handleEditPathway = useCallback(() => {
    setPathwayTrayOpenKey(Date.now())
  }, [])

  const handleEditMilestone = useCallback(
    (milestoneId: string) => {
      const milestone = pathway.milestones.find(m => m.id === milestoneId)
      setActiveMilestone(milestone)
      setMilestoneTrayOpenKey(Date.now())
    },
    [pathway.milestones]
  )

  const handleDeleteMilestone = useCallback(
    async (milestoneIDs: string[]) => {
      const rootMilestone = pathway.milestones.find(m => m.id === milestoneIDs[0])
      if (!rootMilestone) return
      let answer: boolean = false
      if (milestoneIDs.length === 1) {
        answer = await confirm(`Confirm deletion of ${rootMilestone.title}.`, 'Delete step')
      } else {
        answer = await confirm(
          `Confirm deletion of ${rootMilestone.title} and all of the steps beneath it.`,
          'Delete step and prerequisites'
        )
      }
      if (answer) {
        const newMilestones = [...pathway.milestones].filter(m => !milestoneIDs.includes(m.id))
        const newFirstMilestones = [...pathway.first_milestones].filter(
          mid => !milestoneIDs.includes(mid)
        )
        onChange({milestones: newMilestones, first_milestones: newFirstMilestones})
      }
    },
    [onChange, pathway.first_milestones, pathway.milestones]
  )

  const handleSaveMilestone = useCallback(
    (newMilestone: MilestoneData) => {
      setMilestoneTrayOpenKey(0)

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

  const handleSavePathwayDetails = useCallback(
    (newValues: Partial<PathwayDetailData>) => {
      setPathwayTrayOpenKey(0)
      onChange(newValues)
    },
    [onChange]
  )

  return (
    <View
      as="div"
      data-compid="pathway-builder"
      borderWidth="small 0 0 0"
      height="100%"
      position="relative"
    >
      <div
        style={{
          position: 'absolute',
          top: 0,
          right: 0,
          bottom: 0,
          left: 0,
          boxSizing: 'border-box',
        }}
      >
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
      </div>
      <PathwayDetailsTray
        key={pathwayTrayOpenKey}
        pathway={pathway}
        allBadges={allBadges}
        allLearnerGroups={allLearnerGroups}
        selectedBadgeId={pathway.completion_award?.id || null}
        open={pathwayTrayOpenKey > 0}
        onClose={() => setPathwayTrayOpenKey(0)}
        onSave={handleSavePathwayDetails}
      />
      <MilestoneTray
        key={milestoneTrayOpenKey}
        milestone={activeMilestone}
        open={milestoneTrayOpenKey > 0}
        variant="add"
        onClose={() => setMilestoneTrayOpenKey(0)}
        onSave={handleSaveMilestone}
      />
    </View>
  )
}

export default PathwayBuilder
