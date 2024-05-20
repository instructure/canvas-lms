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
import {uid} from '@instructure/uid'
import type {PathwayDetailData, DraftPathway, MilestoneData} from '../../../types'
import PathwayBuilderSidebar from './PathwayBuilderSidebar'
import PathwayBuilderTree from './PathwayBuilderTree'
import MilestoneTray from './MilestoneTray'
import PathwayDetailsTray from './PathwayDetailsTray'
import confirm from '../../../shared/Confirmation'
import {findSubtreeMilestones} from '../../../shared/utils'

function makeDefaultMilestone(): MilestoneData {
  return {
    id: uid('ms', 3),
    title: '',
    description: '',
    required: false,
    requirements: [],
    completion_award: null,
    next_milestones: [],
  }
}

type PathwayBuilderProps = {
  pathway: DraftPathway
  mode: 'create' | 'edit'
  onChange: (newValues: Partial<PathwayDetailData>) => void
}

const PathwayBuilder = ({pathway, mode, onChange}: PathwayBuilderProps) => {
  const [currentRoot, setCurrentRoot] = useState<MilestoneData | null>(null)
  const [sidebarIsVisible, setSidebarIsVisible] = useState(true)
  const [milestoneTrayOpen, setMilestoneTrayOpen] = useState(false)
  const [milestoneTrayVariant, setMilestoneTrayVariant] = useState<'add' | 'edit'>('add')
  const [activeMilestone, setActiveMilestone] = useState<MilestoneData>(makeDefaultMilestone())
  const [pathwayTrayOpen, setPathwayTrayOpen] = useState(mode === 'create')

  const handleShowSidebar = useCallback(() => {
    setSidebarIsVisible(true)
  }, [])

  const handleHideSidebar = useCallback(() => {
    setSidebarIsVisible(false)
  }, [])

  const handleAddMilestone = useCallback(() => {
    setActiveMilestone(makeDefaultMilestone())
    setMilestoneTrayVariant('add')
    setMilestoneTrayOpen(true)
    setPathwayTrayOpen(false)
  }, [])

  const handleEditPathway = useCallback(() => {
    setPathwayTrayOpen(true)
    setMilestoneTrayOpen(false)
  }, [])

  const handleEditMilestone = useCallback(
    (milestoneId: string) => {
      const milestone = pathway.milestones.find(m => m.id === milestoneId)
      setActiveMilestone(milestone || makeDefaultMilestone())
      setMilestoneTrayVariant('edit')
      setMilestoneTrayOpen(true)
      setPathwayTrayOpen(false)
    },
    [pathway.milestones]
  )

  const handleDeleteMilestone = useCallback(
    async (milestoneId: string) => {
      const rootMilestone = pathway.milestones.find(m => m.id === milestoneId)
      if (!rootMilestone) return

      // find the subtree of milestones to delete
      let answer: boolean = false
      const subtree = findSubtreeMilestones(pathway.milestones, milestoneId, [])

      if (subtree.length === 1) {
        answer = await confirm(`Confirm deletion of ${rootMilestone.title}.`, 'Delete step')
      } else {
        answer = await confirm(
          `Confirm deletion of ${rootMilestone.title} and all of the steps beneath it.`,
          'Delete step and prerequisites'
        )
      }
      if (answer) {
        const newMilestones = [...pathway.milestones].filter(m => !subtree.includes(m.id))
        const newFirstMilestones = [...pathway.first_milestones].filter(
          mid => !subtree.includes(mid)
        )
        // remove the deleted milestone from its parents' next_milestones
        newMilestones.forEach(m => {
          m.next_milestones = m.next_milestones.filter(mid => mid !== milestoneId)
        })

        onChange({milestones: newMilestones, first_milestones: newFirstMilestones})
      }
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
          if (currentRoot.next_milestones[0] === 'blank') {
            currentRoot.next_milestones = []
            pathway.timestamp = Date.now()
          }

          const rootMilestone = {...currentRoot}
          if (rootMilestone) {
            rootMilestone.next_milestones.push(newMilestone.id)
          }
        }
        onChange({first_milestones, milestones: [...milestones, newMilestone]})
      }
    },
    [currentRoot, onChange, pathway.first_milestones, pathway.milestones, pathway.timestamp]
  )

  const handleSelectStepFromTree = useCallback(
    (step: MilestoneData | null) => {
      setMilestoneTrayOpen(false)
      setPathwayTrayOpen(false)
      if (currentRoot && currentRoot.next_milestones[0] === 'blank') {
        currentRoot.next_milestones = []
        pathway.timestamp = Date.now()
      }
      if (step?.id === currentRoot?.id) {
        setCurrentRoot(null)
      } else if (step) {
        setCurrentRoot(step)
        if (step.next_milestones.length === 0) {
          step.next_milestones.push('blank')
          pathway.timestamp = Date.now()
        }
      } else {
        setCurrentRoot(null)
      }
    },
    [currentRoot, pathway.timestamp]
  )

  const handleSavePathwayDetails = useCallback(
    (newValues: Partial<PathwayDetailData>) => {
      setPathwayTrayOpen(false)
      onChange(newValues)
    },
    [onChange]
  )

  return (
    <View as="div" id="pathway-builder" borderWidth="small 0 0 0" height="100%" position="relative">
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
        pathway={pathway}
        selectedBadgeId={pathway.completion_award || null}
        open={pathwayTrayOpen}
        onClose={() => setPathwayTrayOpen(false)}
        onSave={handleSavePathwayDetails}
      />
      <MilestoneTray
        milestone={activeMilestone}
        open={milestoneTrayOpen}
        variant={milestoneTrayVariant}
        onClose={() => setMilestoneTrayOpen(false)}
        onSave={handleSaveMilestone}
      />
    </View>
  )
}

export default PathwayBuilder
