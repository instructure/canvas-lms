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
import {useLoaderData, useSubmit} from 'react-router-dom'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {uid} from '@instructure/uid'
import type {PathwayDetailData, PathwayEditData, DraftPathway} from '../../../types'
import AdminHeader from '../../AdminHeader'
import PathwayBuilder from './PathwayBuilder'
import {DataContext} from '../PathwayEditDataContext'

type PathwayEditMode = 'create' | 'edit'

const PathwayEdit = () => {
  const submit = useSubmit()
  const pathway_edit_data = useLoaderData() as PathwayEditData
  const pathway = pathway_edit_data.pathway
  const allBadges = pathway_edit_data.badges
  const allLearnerGroups = pathway_edit_data.learner_groups
  const [mode] = useState<PathwayEditMode>(() => {
    return pathway.id ? 'edit' : 'create'
  })
  const [draftPathway, setDraftPathway] = useState<DraftPathway>(() => {
    const pw = {...pathway, timestamp: Date.now()}
    if (!pw.id) {
      pw.id = uid('pathway', 3)
      pw.title = 'New Pathway'
    }
    return pw
  })

  const handleSubmit = useCallback(
    (asDraft: boolean) => {
      const formData = new FormData()
      formData.set('pathway', JSON.stringify(draftPathway))
      formData.set('draft', asDraft.toString())
      submit(formData, {method: 'POST'})
    },
    [draftPathway, submit]
  )

  const handleSaveAsDraftClick = useCallback(
    _e => {
      handleSubmit(true)
    },
    [handleSubmit]
  )

  const handlePublishClick = useCallback(
    _e => {
      handleSubmit(false)
    },
    [handleSubmit]
  )

  const handlePathwayChange = useCallback(
    (newPathway: Partial<PathwayDetailData>) => {
      const newDraftPathway = {...draftPathway, ...newPathway, timestamp: Date.now()}
      setDraftPathway(newDraftPathway)
    },
    [draftPathway]
  )

  const reqCount = useCallback(() => {
    return draftPathway.milestones.reduce((acc, m) => {
      return acc + m.requirements.length
    }, 0)
  }, [draftPathway.milestones])

  return (
    <DataContext.Provider value={{allBadges, allLearnerGroups}}>
      <Flex as="div" direction="column" alignItems="stretch" height="100%">
        <AdminHeader
          title={
            <>
              <Heading level="h1">{draftPathway.title}</Heading>
              <Text size="small">
                {draftPathway.milestones.length} Milestones | {reqCount()} Requirements
              </Text>
            </>
          }
          breadcrumbs={[
            {
              text: 'Pathways',
              url: `/users/${ENV.current_user.id}/passport/admin/pathways/dashboard`,
            },
            {text: 'Pathway Builder'},
          ]}
        >
          <>
            <Button margin="0 x-small 0 0" onClick={handleSaveAsDraftClick}>
              Save as Draft
            </Button>
            <Button color="primary" margin="0" onClick={handlePublishClick}>
              Publish Pathway
            </Button>
          </>
        </AdminHeader>
        <Flex.Item shouldGrow={true} shouldShrink={false} overflowY="visible">
          <PathwayBuilder pathway={draftPathway} mode={mode} onChange={handlePathwayChange} />
        </Flex.Item>
      </Flex>
    </DataContext.Provider>
  )
}

export default PathwayEdit
