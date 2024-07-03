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

import React, {useEffect, useRef, useState} from 'react'
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
  fetchRubricUsedLocations,
  archiveRubric,
  unarchiveRubric,
} from '../../queries/ViewRubricQueries'
import {RubricAssessmentTray} from '@canvas/rubrics/react/RubricAssessment'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {UsedLocationsModal, type FetchUsedLocationResponse} from '@canvas/grading-scheme'

const {Item: FlexItem} = Flex

const I18n = useI18nScope('rubrics-list-view')

export const TABS = {
  saved: 'Saved',
  archived: 'Archived',
}

export type ViewRubricsProps = {
  canManageRubrics?: boolean
  showHeader?: boolean
}

export const ViewRubrics = ({canManageRubrics = false, showHeader = true}: ViewRubricsProps) => {
  const navigate = useNavigate()
  const {accountId, courseId} = useParams()
  const isAccount = !!accountId
  const isCourse = !!courseId
  const [selectedTab, setSelectedTab] = useState<string | undefined>(TABS.saved)
  const [isPreviewTrayOpen, setIsPreviewTrayOpen] = useState(false)
  const [rubricIdForPreview, setRubricIdForPreview] = useState<string | undefined>(undefined)
  const [searchQuery, setSearchQuery] = useState('')
  const [activeRubrics, setActiveRubrics] = useState<Rubric[]>([])
  const [archivedRubrics, setArchivedRubrics] = useState<Rubric[]>([])
  const [rubricIdForLocations, setRubricIdForLocations] = useState<string>()
  const [loadingUsedLocations, setLoadingUsedLocations] = useState(false)
  const path = useRef<string | undefined>(undefined)

  const handleArchiveRubric = async (rubricId: string) => {
    try {
      await archiveRubric(rubricId)

      const updatedActiveRubrics = activeRubrics.filter(rubric => rubric.id !== rubricId)
      const archivedRubric = activeRubrics.find(rubric => rubric.id === rubricId)
      if (archivedRubric) {
        setArchivedRubrics(prevState => [...prevState, archivedRubric])
      }
      setActiveRubrics(updatedActiveRubrics)
      showFlashSuccess(I18n.t('Rubric archived successfully'))()
    } catch (error) {
      showFlashError(I18n.t('Error Archiving Rubric'))()
    }
  }

  const handleUnarchiveRubric = async (rubricId: string) => {
    try {
      await unarchiveRubric(rubricId)

      const updatedArchivedRubrics = archivedRubrics.filter(rubric => rubric.id !== rubricId)
      const activeRubric = archivedRubrics.find(rubric => rubric.id === rubricId)
      if (activeRubric) {
        setActiveRubrics(prevState => [...prevState, activeRubric])
      }
      setArchivedRubrics(updatedArchivedRubrics)
      showFlashSuccess(I18n.t('Rubric un-archived successfully'))()
    } catch (error) {
      showFlashError(I18n.t('Error Un-Archiving Rubric'))()
    }
  }

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

  useEffect(() => {
    if (data) {
      const {activeRubricsInitialState, archivedRubricsInitialState} =
        data.rubricsConnection.nodes.reduce(
          (prev, curr) => {
            const rubric: Rubric = {
              id: curr.id,
              title: curr.title,
              pointsPossible: curr.pointsPossible,
              criteriaCount: curr.criteriaCount,
              locations: [], // TODO: add locations once we have them
              ratingOrder: curr.ratingOrder,
              hidePoints: curr.hidePoints,
              freeFormCriterionComments: curr.freeFormCriterionComments,
              workflowState: curr.workflowState,
              buttonDisplay: curr.buttonDisplay,
              criteria: curr.criteria ?? [],
              hasRubricAssociations: curr.hasRubricAssociations,
            }

            const activeStates = ['active', 'draft']
            activeStates.includes(curr.workflowState ?? '')
              ? prev.activeRubricsInitialState.push(rubric)
              : prev.archivedRubricsInitialState.push(rubric)
            return prev
          },
          {activeRubricsInitialState: [] as Rubric[], archivedRubricsInitialState: [] as Rubric[]}
        )
      setActiveRubrics(activeRubricsInitialState)
      setArchivedRubrics(archivedRubricsInitialState)
    }
  }, [data])

  if (isLoading) {
    return <LoadingIndicator />
  }

  if (!data) {
    return null
  }

  const handlePreviewClick = (rubricId: string) => {
    if (rubricIdForPreview === rubricId) {
      setRubricIdForPreview(undefined)
      setIsPreviewTrayOpen(false)
      return
    }

    setRubricIdForPreview(rubricId)
    setIsPreviewTrayOpen(true)
  }
  const handleLocationsClick = (rubricId: string) => {
    if (rubricIdForLocations === rubricId) {
      setRubricIdForLocations(undefined)
      return
    }

    setRubricIdForLocations(rubricId)
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

  const handleLocationsUsedModalClose = () => {
    setRubricIdForLocations(undefined)
    path.current = undefined
  }

  const executeFetchLocations = async (): Promise<FetchUsedLocationResponse> => {
    setLoadingUsedLocations(true)
    try {
      const usedLocations = await fetchRubricUsedLocations({
        accountId,
        courseId,
        id: rubricIdForLocations,
        nextPagePath: path.current,
      })

      path.current = usedLocations?.nextPage
      setLoadingUsedLocations(false)
      return usedLocations
    } catch (error) {
      setLoadingUsedLocations(false)
      throw error
    }
  }

  return (
    <View as="div">
      <Flex>
        <FlexItem shouldShrink={true} shouldGrow={true}>
          {showHeader && (
            <Heading level="h1" themeOverride={{h1FontWeight: 700}} margin="medium 0 0 0">
              {I18n.t('Rubrics')}
            </Heading>
          )}
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
          {canManageRubrics && (
            <Button
              renderIcon={IconAddLine}
              color="primary"
              margin="small"
              onClick={() => navigate('./create')}
              data-testid="create-new-rubric-button"
            >
              {I18n.t('Create New Rubric')}
            </Button>
          )}
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
              canManageRubrics={canManageRubrics}
              rubrics={filteredActiveRubrics}
              onLocationsClick={rubricId => handleLocationsClick(rubricId)}
              onPreviewClick={rubricId => handlePreviewClick(rubricId)}
              handleArchiveRubricChange={handleArchiveRubric}
              active={true}
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
              canManageRubrics={canManageRubrics}
              rubrics={filteredArchivedRubrics}
              onLocationsClick={rubricId => handleLocationsClick(rubricId)}
              onPreviewClick={rubricId => handlePreviewClick(rubricId)}
              handleArchiveRubricChange={handleUnarchiveRubric}
              active={false}
            />
          </View>
        </Tabs.Panel>
      </Tabs>

      <RubricAssessmentTray
        isLoading={isLoadingPreview}
        isOpen={isPreviewTrayOpen}
        isPreviewMode={false}
        rubric={rubricPreview}
        rubricAssessmentData={[]}
        onDismiss={() => {
          setRubricIdForPreview(undefined)
          setIsPreviewTrayOpen(false)
        }}
      />

      <UsedLocationsModal
        isLoading={loadingUsedLocations}
        fetchUsedLocations={executeFetchLocations}
        itemId={rubricIdForLocations}
        isOpen={!!rubricIdForLocations}
        onClose={handleLocationsUsedModalClose}
      />
    </View>
  )
}
