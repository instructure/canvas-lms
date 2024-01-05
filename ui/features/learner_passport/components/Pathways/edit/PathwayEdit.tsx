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
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import type {PathwayDetailData, PathwayEditData, SkillData} from '../../types'
import PathwayCreate from './PathwayCreate'
import PathwayBuilder from './PathwayBuilder'
import Path from '@canvas/conditional-release-editor/react/assignment-path'

type PathwayEditSteps = 'create' | 'add_milestones'

const PathwayEdit = () => {
  const submit = useSubmit()
  const create_pathway = useActionData() as PathwayEditData
  const edit_pathway = useLoaderData() as PathwayEditData
  const pathway_data = create_pathway || edit_pathway
  const pathway = pathway_data.pathway
  const allAchievements = pathway_data.achievements
  const [draftPathway, setDraftPathway] = useState(pathway)
  const [currStep, setCurrStep] = useState<PathwayEditSteps>('create')

  const handleChange = useCallback(
    (newValues: Partial<PathwayDetailData>) => {
      const newPathway = {...draftPathway, ...newValues}
      setDraftPathway(newPathway)
    },
    [draftPathway]
  )

  const handleSubmit = useCallback(() => {
    const formData = new FormData()

    formData.append('title', draftPathway.title)
    formData.append('description', draftPathway.description)
    formData.append('is_private', draftPathway.is_private ? 'true' : 'false')
    draftPathway.learning_outcomes.forEach((skill: SkillData) => {
      formData.append('learning_outcomes[]', JSON.stringify(skill))
    })
    formData.append(
      'achievements_earned',
      JSON.stringify(draftPathway.achievements_earned.map(a => a.id))
    )
    formData.append('draft', 'true')

    submit(formData, {method: 'POST'})
  }, [
    draftPathway.achievements_earned,
    draftPathway.description,
    draftPathway.is_private,
    draftPathway.learning_outcomes,
    draftPathway.title,
    submit,
  ])

  const handleCancelClick = useCallback(() => {
    window.history.back()
  }, [])

  const handleSaveAsDraftClick = useCallback(
    _e => {
      handleSubmit()
    },
    [handleSubmit]
  )

  const handleNextClick = useCallback(_e => {
    setCurrStep('add_milestones')
  }, [])

  const handlePathwayChange = useCallback(
    (newPathway: Partial<PathwayDetailData>) => {
      const newDraftPathway = {...draftPathway, ...newPathway}
      setDraftPathway(newDraftPathway)
    },
    [draftPathway]
  )

  const renderStep = useCallback(() => {
    switch (currStep) {
      case 'create':
        return (
          <PathwayCreate
            pathway={draftPathway}
            allAchievements={allAchievements}
            onChange={handleChange}
          />
        )
      case 'add_milestones':
        return <PathwayBuilder pathway={draftPathway} onChange={handlePathwayChange} />
      default:
        return null
    }
  }, [currStep, draftPathway, allAchievements, handleChange, handlePathwayChange])

  const renderBreadcrumbsForStep = useCallback(() => {
    switch (currStep) {
      case 'create':
        return (
          <Breadcrumb label="You are here:" size="small">
            <Breadcrumb.Link href={`/users/${ENV.current_user.id}/passport/pathways/dashboard`}>
              Pathways
            </Breadcrumb.Link>
            <Breadcrumb.Link>Create Pathway</Breadcrumb.Link>
          </Breadcrumb>
        )
      case 'add_milestones':
        return (
          <Breadcrumb label="You are here:" size="small">
            <Breadcrumb.Link href={`/users/${ENV.current_user.id}/passport/pathways/dashboard`}>
              Pathways
            </Breadcrumb.Link>
            <Breadcrumb.Link href={window.location.href}>Create Pathway</Breadcrumb.Link>
            <Breadcrumb.Link>Add Milestones</Breadcrumb.Link>
          </Breadcrumb>
        )
      default:
        return null
    }
  }, [currStep])

  const renderHeadingForStep = useCallback(() => {
    switch (currStep) {
      case 'create':
        return 'Create Pathway'
      case 'add_milestones':
        return draftPathway.title
      default:
        return null
    }
  }, [currStep, draftPathway.title])

  return (
    <div style={{margin: '0 -3rem'}}>
      <View as="div" borderWidth="0 0 small 0" borderColor="primary">
        <div style={{padding: '0 3rem'}}>
          {renderBreadcrumbsForStep()}
          <Flex as="div" margin="medium 0 x-large 0" justifyItems="space-between" gap="small">
            <Flex.Item shouldGrow={true}>
              <Heading level="h1">{renderHeadingForStep()}</Heading>
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
        </div>
      </View>
      {renderStep()}
    </div>
  )
}

export default PathwayEdit
