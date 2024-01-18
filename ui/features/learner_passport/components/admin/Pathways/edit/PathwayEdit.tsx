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
import {useActionData, useLoaderData, useNavigate, useSubmit} from 'react-router-dom'
import {Breadcrumb} from '@instructure/ui-breadcrumb'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import type {PathwayDetailData, PathwayEditData, DraftPathway} from '../../../types'
import PathwayInfo from './PathwayInfo'
import PathwayBuilder from './PathwayBuilder'

type PathwayEditSteps = 'create' | 'add_milestones'

const PathwayEdit = () => {
  const submit = useSubmit()
  const navigate = useNavigate()
  const create_pathway = useActionData() as PathwayEditData
  const edit_pathway = useLoaderData() as PathwayEditData
  const pathway_data = create_pathway || edit_pathway
  const pathway = pathway_data.pathway
  const allBadges = pathway_data.badges
  const allLearnerGroups = pathway_data.learner_groups
  const [draftPathway, setDraftPathway] = useState<DraftPathway>(() => {
    return {...pathway, timestamp: Date.now()}
  })
  const [currStep, setCurrStep] = useState<PathwayEditSteps>(() => {
    switch (window.location.hash) {
      case '#add_milestones':
        return 'add_milestones'
      case '#create':
      default:
        return 'create'
    }
  })

  const handleHashChange = useCallback(() => {
    switch (window.location.hash) {
      case '#add_milestones':
        setCurrStep('add_milestones')
        break
      case '#create':
      default:
        setCurrStep('create')
        break
    }
  }, [])

  useEffect(() => {
    window.addEventListener('hashchange', handleHashChange)
    return () => window.removeEventListener('hashchange', handleHashChange)
  }, [handleHashChange])

  useEffect(() => {
    window.location.hash = currStep
  }, [currStep])

  const handleChange = useCallback(
    (newValues: Partial<PathwayDetailData>) => {
      const newPathway = {...draftPathway, ...newValues}
      setDraftPathway(newPathway)
    },
    [draftPathway]
  )

  const handleSubmit = useCallback(() => {
    const formData = new FormData()
    formData.set('pathway', JSON.stringify(draftPathway))
    formData.set('draft', 'true')
    submit(formData, {method: 'POST'})
  }, [draftPathway, submit])

  const handleCancelClick = useCallback(() => {
    navigate('../dashboard')
  }, [navigate])

  const handleSaveAsDraftClick = useCallback(
    _e => {
      handleSubmit()
    },
    [handleSubmit]
  )

  const handleNextClick = useCallback(
    _e => {
      if (draftPathway.title === '') return
      setCurrStep('add_milestones')
    },
    [draftPathway.title]
  )

  const handlePathwayChange = useCallback(
    (newPathway: Partial<PathwayDetailData>) => {
      const newDraftPathway = {...draftPathway, ...newPathway, timestamp: Date.now()}
      setDraftPathway(newDraftPathway)
    },
    [draftPathway]
  )

  const renderStep = useCallback(() => {
    switch (currStep) {
      case 'create':
        return (
          <PathwayInfo
            pathway={draftPathway}
            allBadges={allBadges}
            allLearnerGroups={allLearnerGroups}
            onChange={handleChange}
          />
        )
      case 'add_milestones':
        return <PathwayBuilder pathway={draftPathway} onChange={handlePathwayChange} />
      default:
        return null
    }
  }, [currStep, draftPathway, allBadges, allLearnerGroups, handleChange, handlePathwayChange])

  const renderBreadcrumbsForStep = useCallback(() => {
    switch (currStep) {
      case 'create':
        return (
          <Breadcrumb label="You are here:" size="small">
            <Breadcrumb.Link
              href={`/users/${ENV.current_user.id}/passport/admin/pathways/dashboard`}
            >
              Pathways
            </Breadcrumb.Link>
            <Breadcrumb.Link>Create Pathway</Breadcrumb.Link>
          </Breadcrumb>
        )
      case 'add_milestones': {
        const loc = new URL(window.location.href)
        loc.hash = 'create'
        const href = loc.href
        return (
          <Breadcrumb label="You are here:" size="small">
            <Breadcrumb.Link
              href={`/users/${ENV.current_user.id}/passport/admin/pathways/dashboard`}
            >
              Pathways
            </Breadcrumb.Link>
            <Breadcrumb.Link href={href}>Create Pathway</Breadcrumb.Link>
            <Breadcrumb.Link>Add Milestones</Breadcrumb.Link>
          </Breadcrumb>
        )
      }
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
