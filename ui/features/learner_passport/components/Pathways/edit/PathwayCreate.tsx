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
import {Checkbox} from '@instructure/ui-checkbox'
import {FormField} from '@instructure/ui-form-field'
import {Text} from '@instructure/ui-text'
import {TextArea} from '@instructure/ui-text-area'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import type {PathwayDetailData, AchievementData, SkillData} from '../../types'
import SkillSelect from '../../shared/SkillSelect'
import {AchievementsEdit} from '../../Portfolios/edit/achievements/AchievementsEdit'
import {stringToId} from '../../shared/utils'

type PathwayCreateProps = {
  pathway: PathwayDetailData
  allAchievements: AchievementData[]
  onChange: (newValues: Partial<PathwayDetailData>) => void
}

const PathwayCreate = ({pathway, allAchievements, onChange}: PathwayCreateProps) => {
  const [achievementIds, setAchievementIds] = useState<string[]>(() => {
    return pathway.achievements_earned.map(achievement => achievement.id)
  })

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

  const handlePrivateChange = useCallback(
    (event: React.ChangeEvent<HTMLInputElement>) => {
      const newPrivate = event.target.checked
      onChange({is_private: newPrivate})
    },
    [onChange]
  )

  const handleSelectSkills = useCallback(
    (newSkills: SkillData[]) => {
      onChange({learning_outcomes: newSkills})
    },
    [onChange]
  )

  const handleNewAchievements = useCallback(
    (newAchievementIds: string[]) => {
      const newAchievements = allAchievements.filter(achievement =>
        newAchievementIds.includes(achievement.id)
      )
      setAchievementIds(newAchievementIds)

      onChange({achievements_earned: newAchievements})
    },
    [allAchievements, onChange]
  )

  return (
    <View as="div" maxWidth="1100px" margin="large auto 0">
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
        <Checkbox
          label="Set pathway to private"
          name="is_private"
          checked={pathway.is_private}
          value={pathway?.is_private?.toString() || 'false'}
          onChange={handlePrivateChange}
          variant="toggle"
        />
      </View>
      <View as="div" margin="medium 0 0 0">
        <SkillSelect
          label="Learning Outcomes"
          objectSkills={pathway.learning_outcomes}
          selectedSkillIds={pathway.learning_outcomes.map((s: SkillData) => stringToId(s.name))}
          onSelect={handleSelectSkills}
        />
      </View>
      <View as="div" margin="medium 0 0 0">
        <FormField id="achievements" label="Achievements">
          <input type="hidden" name="achievements_earned" value={JSON.stringify(achievementIds)} />

          <Text>
            The learner will be awarded the following achievements when the requirements for this
            pathway are met.
          </Text>
          <AchievementsEdit
            allAchievements={allAchievements}
            selectedAchievementIds={achievementIds}
            onChange={handleNewAchievements}
          />
        </FormField>
      </View>
    </View>
  )
}

export default PathwayCreate
