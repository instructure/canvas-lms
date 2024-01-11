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
import {IconAddLine} from '@instructure/ui-icons'
import {Button} from '@instructure/ui-buttons'
import {FormField} from '@instructure/ui-form-field'
import {Text} from '@instructure/ui-text'
import {TextArea} from '@instructure/ui-text-area'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import type {PathwayDetailData, PathwayBadgeType} from '../../../types'
import AddBadgeModal from './AddBadgeModal'
import PathwayBadgeCard from './PathwayBadgeCard'
import {showUnimplemented} from '../../../shared/utils'

type PathwayInfoProps = {
  pathway: PathwayDetailData
  allBadges: PathwayBadgeType[]
  onChange: (newValues: Partial<PathwayDetailData>) => void
}

const PathwayInfo = ({pathway, allBadges, onChange}: PathwayInfoProps) => {
  const [achievementModalIsOpen, setAchievementModalIsOpen] = useState(false)

  const handleTitleChange = useCallback(
    (event: React.ChangeEvent<HTMLInputElement>, newTitle: string) => {
      onChange({title: newTitle})
    },
    [onChange]
  )

  const handleDescriptionChange = useCallback(
    (event: React.ChangeEvent<HTMLTextAreaElement>) => {
      const newDescription = event.target.value
      onChange({description: newDescription})
    },
    [onChange]
  )

  const handleOpenAchievements = useCallback(() => {
    setAchievementModalIsOpen(true)
  }, [])

  const handleCloseAchievements = useCallback(() => {
    setAchievementModalIsOpen(false)
  }, [])

  const handleSelectAchievement = useCallback(
    (newAchievementId: string | null) => {
      setAchievementModalIsOpen(false)
      let newAchievement = null
      if (newAchievementId) {
        newAchievement = allBadges.find(ach => ach.id === newAchievementId)
      }
      onChange({completion_award: newAchievement})
    },
    [allBadges, onChange]
  )

  const handleRemoveAchievement = useCallback(() => {
    onChange({completion_award: null})
  }, [onChange])

  return (
    <View as="div" maxWidth="1100px" margin="large auto large auto">
      <View as="div">
        <TextInput
          renderLabel="Name"
          name="title"
          value={pathway.title}
          onChange={handleTitleChange}
          placeholder="Pathway Name"
          isRequired={true}
        />
      </View>
      <View as="div" margin="medium 0 0 0">
        <TextArea
          label="Description"
          name="description"
          value={pathway.description}
          onChange={handleDescriptionChange}
          height="8rem"
          placeholder="Pathway Description"
        />
      </View>
      <View as="div" margin="medium 0 0 0">
        <FormField id="achievement" label="Pathway Completion Achievement">
          <Text>
            Add a badge or certificate that the learner will receive when the pathway is completed.
            The skills associated with that achievement will be linked as well.
          </Text>
          {pathway.completion_award && (
            <View as="div" margin="small 0 0 0">
              <PathwayBadgeCard
                badge={pathway.completion_award}
                onRemove={handleRemoveAchievement}
              />
            </View>
          )}
          <Button renderIcon={IconAddLine} margin="small 0 0 0" onClick={handleOpenAchievements}>
            Add Award
          </Button>
          <AddBadgeModal
            allBadges={allBadges}
            open={achievementModalIsOpen}
            selectedBadgeId={pathway.completion_award?.id || null}
            onClose={handleCloseAchievements}
            onSave={handleSelectAchievement}
          />
        </FormField>
        <View as="div" margin="medium 0 0 0">
          <FormField id="learner_group" label="Learner Groups">
            <Text>
              Add learners who will be participating in the pathway. You can also add groups later.
            </Text>
            <View as="div" margin="small 0 0 0">
              <Button renderIcon={IconAddLine} onClick={showUnimplemented}>
                Add Learner Group
              </Button>
              <Button renderIcon={IconAddLine} margin="0 0 0 small" onClick={showUnimplemented}>
                Create Learner Group
              </Button>
            </View>
          </FormField>
        </View>
      </View>
    </View>
  )
}

export default PathwayInfo
