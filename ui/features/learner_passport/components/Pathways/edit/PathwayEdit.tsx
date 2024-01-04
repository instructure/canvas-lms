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
import {useActionData, useLoaderData, useSubmit} from 'react-router-dom'
import {Breadcrumb} from '@instructure/ui-breadcrumb'
import {Button} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {FormField} from '@instructure/ui-form-field'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {TextArea} from '@instructure/ui-text-area'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import type {PathwayEditData, SkillData} from '../../types'
import SkillSelect from '../../shared/SkillSelect'
import {AchievementsEdit} from '../../Portfolios/edit/achievements/AchievementsEdit'
import {showUnimplemented, stringToId} from '../../shared/utils'

const PathwayEdit = () => {
  const submit = useSubmit()
  const create_pathway = useActionData() as PathwayEditData
  const edit_pathway = useLoaderData() as PathwayEditData
  const pathway_data = create_pathway || edit_pathway
  const pathway = pathway_data.pathway
  const allAchievements = pathway_data.achievements
  const [achievementIds, setAchievementIds] = useState<string[]>(() => {
    return pathway.achievements_earned.map(achievement => achievement.id)
  })
  const [title, setTitle] = useState(pathway.title)
  const [description, setDescription] = useState(pathway.description)
  const [isPrivate, setIsPrivate] = useState(!!pathway.is_private)
  const [skills, setSkills] = useState(pathway.learning_outcomes)

  const handleSubmit = useCallback(
    (e: React.FormEvent<HTMLFormElement>) => {
      e.preventDefault()
      const form = document.getElementById('edit_pathway_form') as HTMLFormElement
      const formData = new FormData(form)

      formData.delete('learning_outcomes')
      skills.forEach((skill: SkillData) => {
        formData.append('learning_outcomes[]', JSON.stringify(skill))
      })
      formData.append('draft', 'true')

      submit(formData, {method: 'POST'})
    },
    [skills, submit]
  )

  const handleTitleChange = useCallback(
    (event: React.ChangeEvent<HTMLInputElement>, newTitle: string) => {
      setTitle(newTitle)
    },
    []
  )

  const handleDescriptionChange = useCallback((event: React.ChangeEvent<HTMLTextAreaElement>) => {
    const newDescription = event.target.value
    setDescription(newDescription)
  }, [])

  const handlePrivateChange = useCallback((event: React.ChangeEvent<HTMLInputElement>) => {
    const newPrivate = event.target.checked
    setIsPrivate(newPrivate)
  }, [])

  const handleSelectSkills = useCallback((newSkills: SkillData[]) => {
    setSkills(newSkills)
  }, [])

  const handleNewAchievements = useCallback((newAchievementIds: string[]) => {
    setAchievementIds(newAchievementIds)
  }, [])

  const handleCancelClick = useCallback(() => {
    window.history.back()
  }, [])

  const handleSaveAsDraftClick = useCallback(_e => {
    ;(document.getElementById('edit_pathway_form') as HTMLFormElement)?.requestSubmit()
  }, [])

  const handleNextClick = useCallback(e => {
    showUnimplemented(e)
  }, [])

  return (
    <View as="div">
      <Breadcrumb label="You are here:" size="small">
        <Breadcrumb.Link href={`/users/${ENV.current_user.id}/passport/pathways/dashboard`}>
          Pathways
        </Breadcrumb.Link>
        <Breadcrumb.Link
          href={`/users/${ENV.current_user.id}/passport/pathways/view/${pathway.id}`}
        >
          {pathway.title}
        </Breadcrumb.Link>
        <Breadcrumb.Link>Edit</Breadcrumb.Link>
      </Breadcrumb>
      <View as="div" borderWidth="0 0 small 0" borderColor="primary">
        <Flex as="div" margin="medium 0 x-large 0" justifyItems="space-between" gap="small">
          <Flex.Item shouldGrow={true}>
            <Heading level="h1">Create Pathway</Heading>
          </Flex.Item>
          <Flex.Item>
            <Button margin="0 x-small 0 0" onClick={handleCancelClick}>
              Cancel
            </Button>
            <Button margin="0 x-small 0 0" onClick={handleSaveAsDraftClick}>
              Save as Draft
            </Button>
            <Button color="primary" margin="0" onClick={handleNextClick}>
              Next
            </Button>
          </Flex.Item>
        </Flex>
      </View>
      <View as="div" maxWidth="1100px" margin="large auto 0">
        <form id="edit_pathway_form" method="POST" onSubmit={handleSubmit}>
          <View as="div">
            <TextInput
              renderLabel="Name"
              name="title"
              value={title}
              onChange={handleTitleChange}
              placeholder="Pathway Name"
              isRequired={true}
            />
          </View>
          <View as="div" margin="medium 0 0 0">
            <TextArea
              label="Description"
              name="description"
              value={description}
              onChange={handleDescriptionChange}
              height="8rem"
              placeholder="Pathway Description"
            />
          </View>
          <View as="div" margin="medium 0 0 0">
            <Checkbox
              label="Set pathway to private"
              name="is_private"
              checked={isPrivate}
              value={isPrivate.toString()}
              onChange={handlePrivateChange}
              variant="toggle"
            />
          </View>
          <View as="div" margin="medium 0 0 0">
            <input type="hidden" name="learning_outcomes" value={JSON.stringify(skills)} />
            <SkillSelect
              label="Learning Outcomes"
              objectSkills={skills}
              selectedSkillIds={skills.map((s: SkillData) => stringToId(s.name))}
              onSelect={handleSelectSkills}
            />
          </View>
          <View as="div" margin="medium 0 0 0">
            <FormField id="achievements" label="Achievements">
              <input
                type="hidden"
                name="achievements_earned"
                value={JSON.stringify(achievementIds)}
              />

              <Text>
                The learner will be awarded the following achievements when the requirements for
                this pathway are met.
              </Text>
              <AchievementsEdit
                allAchievements={allAchievements}
                selectedAchievementIds={achievementIds}
                onChange={handleNewAchievements}
              />
            </FormField>
          </View>
        </form>
      </View>
    </View>
  )
}

export default PathwayEdit
