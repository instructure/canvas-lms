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

import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {FormField} from '@instructure/ui-form-field'
import {Heading} from '@instructure/ui-heading'
import {IconAddLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {TextArea} from '@instructure/ui-text-area'
import {TextInput} from '@instructure/ui-text-input'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import type {
  LearnerGroupType,
  PathwayDetailData,
  PathwayBadgeType,
  PathwayUserShareType,
} from '../../../types'
import AddBadgeTray, {renderBadges} from './AddBadgeTray'
import AddLearnerGroupsTray, {LearnerGroupCard} from './AddLearnerGroupsTray'
import CanvasUserFinder from './shares/CanvasUserFinder'
import {showUnimplemented} from '../../../shared/utils'

type PathwayDetailsTrayProps = {
  pathway: PathwayDetailData
  allBadges: PathwayBadgeType[]
  allLearnerGroups: LearnerGroupType[]
  selectedBadgeId: string | null
  open: boolean
  onClose: () => void
  onSave: (badgeId: Partial<PathwayDetailData>) => void
}

const PathwayDetailsTray = ({
  pathway,
  allBadges,
  allLearnerGroups,
  selectedBadgeId,
  open,
  onClose,
  onSave,
}: PathwayDetailsTrayProps) => {
  const [title, setTitle] = useState(pathway.title)
  const [description, setDescription] = useState(pathway.description)
  const [currSelectedBadgeId, setCurrSelectedBadgeId] = useState<string | null>(selectedBadgeId)
  const [selectedLearnerGroupIds, setSelectedLearnerGroupIds] = useState<string[]>(
    pathway.learner_groups
  )
  const [selectedShares, setSelectedShares] = useState<PathwayUserShareType[]>(pathway.shares)
  const [addBadgeTrayOpenKey, setAddBadgeTrayOpenKey] = useState(0)
  const [addLearnerGroupsTrayOpenKey, setAddLearnerGroupsTrayOpenKey] = useState(0)

  const handleCancel = useCallback(() => {
    setTitle(pathway.title)
    setDescription(pathway.description)
    setCurrSelectedBadgeId(selectedBadgeId)
    setSelectedLearnerGroupIds(pathway.learner_groups)
    setSelectedShares([])
    onClose()
  }, [onClose, pathway.description, pathway.learner_groups, pathway.title, selectedBadgeId])

  const handleSave = useCallback(() => {
    if (!title) return
    const badge = allBadges.find(b => b.id === currSelectedBadgeId)
    onSave({
      title,
      description,
      completion_award: badge?.id || null,
      learner_groups: selectedLearnerGroupIds,
      shares: selectedShares,
    })
  }, [
    allBadges,
    currSelectedBadgeId,
    description,
    onSave,
    selectedLearnerGroupIds,
    selectedShares,
    title,
  ])

  const handleTitleChange = useCallback(
    (event: React.ChangeEvent<HTMLInputElement>, newTitle: string) => {
      setTitle(newTitle.trim())
    },
    []
  )

  const handleDescriptionChange = useCallback((event: React.ChangeEvent<HTMLTextAreaElement>) => {
    const newDescription = event.target.value
    setDescription(newDescription)
  }, [])

  const handleAddAchievementClick = useCallback(() => {
    setAddBadgeTrayOpenKey(Date.now())
  }, [])

  const handleSaveBadge = useCallback((badgeId: string | null) => {
    setCurrSelectedBadgeId(badgeId)
    setAddBadgeTrayOpenKey(0)
  }, [])

  const handleAddLearnerGroupClick = useCallback(() => {
    setAddLearnerGroupsTrayOpenKey(Date.now())
  }, [])

  const handleSaveLearnerGroups = useCallback((learnerGroupIds: string[]) => {
    setSelectedLearnerGroupIds(learnerGroupIds)
    setAddLearnerGroupsTrayOpenKey(0)
  }, [])

  const handleChangeSharedUser = useCallback((users: PathwayUserShareType[]) => {
    setSelectedShares(users)
  }, [])

  return (
    <View as="div">
      <Tray label="Pathway Details" open={open} onDismiss={onClose} size="regular" placement="end">
        <Flex as="div" direction="column" height="100vh">
          <Flex as="div" padding="small small medium medium">
            <Flex.Item shouldGrow={true} shouldShrink={true}>
              <Heading level="h2" margin="0 0 small 0">
                Pathway Details
              </Heading>
            </Flex.Item>
            <Flex.Item>
              <CloseButton
                placement="end"
                offset="small"
                screenReaderLabel="Close"
                onClick={onClose}
              />
            </Flex.Item>
          </Flex>
          <Flex.Item overflowY="auto" shouldShrink={true}>
            <View as="div" padding="0 medium medium medium">
              <View as="div" padding="0 0 medium 0" borderWidth="0 0 small 0">
                <View as="div" margin="0 0 small 0">
                  <TextInput
                    isRequired={true}
                    placeholder="Enter pathway name"
                    renderLabel="Pathway Name"
                    value={title}
                    onChange={handleTitleChange}
                    messages={
                      title ? undefined : [{text: 'Pathway name is Required', type: 'error'}]
                    }
                  />
                </View>
                <View as="div" margin="0 0 small 0">
                  <TextArea
                    label="Step Description"
                    placeholder="Enter pathway description"
                    value={description}
                    onChange={handleDescriptionChange}
                  />
                </View>
              </View>
              <View as="div" padding="medium 0" borderWidth="0 0 small 0">
                <FormField id="pathway-achievements" label="Pathway Completion Achievement">
                  <Text as="div" size="small">
                    Add a badge or certificate that the learner will receive when the pathway is
                    completed. The skills associated with that achievement will be linked as well.
                  </Text>
                  {renderBadges(allBadges, currSelectedBadgeId)}
                  <Button
                    margin="small 0 0 0"
                    onClick={handleAddAchievementClick}
                    renderIcon={IconAddLine}
                  >
                    Add Achievement
                  </Button>
                </FormField>
              </View>
              <View as="div" padding="medium 0" borderWidth="0 0 small 0">
                <FormField id="pathway-learner-groups" label="Learner Groups">
                  <Text as="div" size="small">
                    Add learner groups to this pathway. You can also add groups later.
                  </Text>
                  {selectedLearnerGroupIds.length > 0 && (
                    <Flex as="div" margin="small 0 0 0" direction="column" gap="small">
                      {selectedLearnerGroupIds.map(id => {
                        const group = allLearnerGroups.find(g => g.id === id)
                        if (group) {
                          return <LearnerGroupCard key={id} group={group} />
                        }
                        return null
                      })}
                    </Flex>
                  )}
                  <Button
                    margin="small 0 0 0"
                    renderIcon={IconAddLine}
                    onClick={handleAddLearnerGroupClick}
                  >
                    Add Learner Groups
                  </Button>
                  <Button
                    margin="small 0 0 x-small"
                    renderIcon={IconAddLine}
                    onClick={showUnimplemented}
                  >
                    Create Learner Group
                  </Button>
                </FormField>
              </View>
              <View as="div" padding="medium 0">
                <CanvasUserFinder
                  selectedUsers={selectedShares}
                  onChange={handleChangeSharedUser}
                />
              </View>
            </View>
          </Flex.Item>
          <Flex.Item align="end" width="100%">
            <View as="div" padding="small medium" borderWidth="small 0 0 0" textAlign="end">
              <Button onClick={handleCancel}>Cancel</Button>
              <Button margin="0 0 0 small" onClick={handleSave}>
                Save Pathway Details
              </Button>
            </View>
          </Flex.Item>
        </Flex>
      </Tray>
      <AddBadgeTray
        key={addBadgeTrayOpenKey}
        open={addBadgeTrayOpenKey > 0}
        selectedBadgeId={currSelectedBadgeId}
        allBadges={allBadges}
        onClose={() => setAddBadgeTrayOpenKey(0)}
        onSave={handleSaveBadge}
      />
      <AddLearnerGroupsTray
        key={addLearnerGroupsTrayOpenKey}
        open={addLearnerGroupsTrayOpenKey > 0}
        allLearnerGroups={allLearnerGroups}
        selectedLearnerGroupIds={selectedLearnerGroupIds}
        onClose={() => setAddLearnerGroupsTrayOpenKey(0)}
        onSave={handleSaveLearnerGroups}
      />
    </View>
  )
}

export default PathwayDetailsTray
