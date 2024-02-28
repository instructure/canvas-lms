/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useState} from 'react'
import {useNavigate, useParams} from 'react-router-dom'
import {useQuery} from '@canvas/query'
import {useScope as useI18nScope} from '@canvas/i18n'
import LoadingIndicator from '@canvas/loading-indicator'
import type {Rubric} from '@canvas/rubrics/react/types/rubric'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconAddLine, IconSearchLine} from '@instructure/ui-icons'
import {TextInput} from '@instructure/ui-text-input'
import {Tabs} from '@instructure/ui-tabs'
import {View} from '@instructure/ui-view'
import {RubricTable} from './RubricTable'
import type {RubricQueryResponse} from '../../types/Rubric'
import {
  type FetchRubricVariables,
  fetchAccountRubrics,
  fetchCourseRubrics,
  fetchRubricCriterion,
} from '../../queries/ViewRubricQueries'
import {RubricAssessmentTray} from '@canvas/rubrics/react/RubricAssessment'

const {Item: FlexItem} = Flex

const I18n = useI18nScope('rubrics-list-view')

export const TABS = {
  saved: 'Saved',
  archived: 'Archived',
}

export const ViewRubrics = () => {
  const navigate = useNavigate()
  const {accountId, courseId} = useParams()
  const isAccount = !!accountId
  const isCourse = !!courseId
  const [selectedTab, setSelectedTab] = useState<string | undefined>(TABS.saved)
  const [isPreviewTrayOpen, setIsPreviewTrayOpen] = useState(false)
  const [rubricIdForPreview, setRubricIdForPreview] = useState<string | undefined>(undefined)
  const [searchQuery, setSearchQuery] = useState('')

  let queryVariables: FetchRubricVariables
  let fetchQuery: (queryVariables: FetchRubricVariables) => Promise<RubricQueryResponse>
  let queryKey: string = ''

  if (isAccount) {
    queryVariables = {accountId}
    fetchQuery = fetchAccountRubrics
    queryKey = `accountRubrics-${accountId}`
  } else if (isCourse) {
    queryVariables = {courseId}
    fetchQuery = fetchCourseRubrics
    queryKey = `courseRubrics-${courseId}`
  }

  const {data, isLoading} = useQuery({
    queryKey: [queryKey],
    queryFn: async () => fetchQuery(queryVariables),
  })

  const {data: rubricPreview, isLoading: isLoadingPreview} = useQuery({
    queryKey: [`rubric-preview-${rubricIdForPreview}`],
    queryFn: async () => fetchRubricCriterion(rubricIdForPreview),
    enabled: !!rubricIdForPreview,
  })

  if (isLoading) {
    return <LoadingIndicator />
  }

  if (!data) {
    return null
  }

  const {activeRubrics, archivedRubrics} = data.rubricsConnection.nodes.reduce(
    (prev, curr) => {
      const rubric: Rubric = {
        id: curr.id,
        title: curr.title,
        pointsPossible: curr.pointsPossible,
        criteriaCount: curr.criteriaCount,
        locations: [], // TODO: add locations once we have them
        ratingOrder: curr.ratingOrder,
        hidePoints: curr.hidePoints,
        workflowState: curr.workflowState,
        buttonDisplay: curr.buttonDisplay,
        criteria: curr.criteria,
        hasRubricAssociations: curr.hasRubricAssociations,
      }

      const activeStates = ['active', 'draft']
      activeStates.includes(curr.workflowState ?? '')
        ? prev.activeRubrics.push(rubric)
        : prev.archivedRubrics.push(rubric)
      return prev
    },
    {activeRubrics: [] as Rubric[], archivedRubrics: [] as Rubric[]}
  )

  const handlePreviewClick = (rubricId: string) => {
    if (rubricIdForPreview === rubricId) {
      setRubricIdForPreview(undefined)
      setIsPreviewTrayOpen(false)
      return
    }

    setRubricIdForPreview(rubricId)
    setIsPreviewTrayOpen(true)
  }
  const filteredActiveRubrics =
    searchQuery.trim() !== ''
      ? activeRubrics.filter(rubric =>
          rubric.title.toLowerCase().includes(searchQuery.toLowerCase())
        )
      : activeRubrics

  const filteredArchivedRubrics =
    searchQuery.trim() !== ''
      ? archivedRubrics.filter(rubric =>
          rubric.title.toLowerCase().includes(searchQuery.toLowerCase())
        )
      : archivedRubrics

  return (
    <View as="div">
      <Flex>
        <FlexItem shouldShrink={true} shouldGrow={true}>
          <Heading level="h1" themeOverride={{h1FontWeight: 700}} margin="medium 0 0 0">
            {I18n.t('Rubrics')}
          </Heading>
        </FlexItem>
        <FlexItem>
          <TextInput
            renderLabel={<ScreenReaderContent>{I18n.t('Search Rubrics')}</ScreenReaderContent>}
            placeholder={I18n.t('Search...')}
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
            width="17"
            renderBeforeInput={<IconSearchLine inline={false} />}
            data-testid="rubric-search-bar"
          />
        </FlexItem>
        <FlexItem>
          <Button
            renderIcon={IconAddLine}
            color="primary"
            margin="small"
            onClick={() => navigate('./create')}
          >
            {I18n.t('Create New Rubric')}
          </Button>
        </FlexItem>
      </Flex>

      <Tabs
        margin="large auto"
        padding="medium"
        onRequestTabChange={(_e: any, {id}: {id?: string}) => setSelectedTab(id)}
      >
        <Tabs.Panel
          id={TABS.saved}
          data-testid="saved-rubrics-panel"
          renderTitle={I18n.t('Saved')}
          isSelected={selectedTab === TABS.saved}
          padding="none"
        >
          <View as="div" margin="medium 0" data-testid="saved-rubrics-table">
            <RubricTable
              rubrics={filteredActiveRubrics}
              onPreviewClick={rubricId => handlePreviewClick(rubricId)}
            />
          </View>
        </Tabs.Panel>
        <Tabs.Panel
          id={TABS.archived}
          data-testid="archived-rubrics-panel"
          renderTitle={I18n.t('Archived')}
          isSelected={selectedTab === TABS.archived}
          padding="none"
        >
          <View as="div" margin="medium 0" data-testid="archived-rubrics-table">
            <RubricTable
              rubrics={filteredArchivedRubrics}
              onPreviewClick={rubricId => handlePreviewClick(rubricId)}
            />
          </View>
        </Tabs.Panel>
      </Tabs>

      <RubricAssessmentTray
        isLoading={isLoadingPreview}
        isOpen={isPreviewTrayOpen}
        isPreviewMode={true}
        rubric={rubricPreview}
        rubricAssessmentData={[]}
        onDismiss={() => setIsPreviewTrayOpen(false)}
      />
    </View>
  )
}
