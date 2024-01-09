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
import {CondensedButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import type {PathwayDetailData, MilestoneData, MilestoneId} from '../../../types'
import PathwayBuilderSidebar from './PathwayBuilderSidebar'
import PathwayBuilderTree from './PathwayBuilderTree'
import MilestoneTray from './MilestoneTray'

type PathwayBuilderProps = {
  pathway: PathwayDetailData
  onChange: (newValues: Partial<PathwayDetailData>) => void
}

const PathwayBuilder = ({pathway, onChange}: PathwayBuilderProps) => {
  const [currentRoot, setCurrentRoot] = useState<MilestoneId | null>(null)
  const [milestoneTrayOpen, setMilestoneTrayOpen] = useState(false)
  const [milestoneTrayOpenCount, setMilestoneTrayOpenCount] = useState(0)
  const [treeVersion, setTreeVersion] = useState(0)
  const [sidebarIsVisible, setSidebarIsVisible] = useState(true)

  const handleShowSidebar = useCallback(() => {
    setSidebarIsVisible(true)
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
      setTreeVersion(treeVersion + 1)
      setMilestoneTrayOpen(false)
      if (currentRoot === null) {
        pathway.first_milestones.push(newMilestone.id)
      } else {
        const rootMilestone = pathway.milestones.find(ms => ms.id === currentRoot)
        if (rootMilestone) {
          rootMilestone.next_milestones.push(newMilestone.id)
        }
      }
      onChange({milestones: [...pathway.milestones, newMilestone]})
    },
    [currentRoot, onChange, pathway.first_milestones, pathway.milestones, treeVersion]
  )

  return (
    <View as="div" height="100vh">
      <Flex as="div" alignItems="stretch" height="100%">
        <Flex.Item shouldShrink={true}>
          {sidebarIsVisible ? (
            <PathwayBuilderSidebar
              pathway={pathway}
              onAddStep={handleAddMilestone}
              onHideSidebar={handleHideSidebar}
            />
          ) : null}
        </Flex.Item>
        <Flex.Item shouldGrow={true}>
          <PathwayBuilderTree
            pathway={pathway}
            onShowSidebar={sidebarIsVisible ? undefined : handleShowSidebar}
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
