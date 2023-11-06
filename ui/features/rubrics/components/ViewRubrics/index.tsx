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

import React from 'react'
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
import {View} from '@instructure/ui-view'
import {RubricTable} from './RubricTable'
import {RubricQueryResponse} from '../../types/Rubric'
import {
  FetchRubricVariables,
  fetchAccountRubrics,
  fetchCourseRubrics,
} from '../../queries/ViewRubricQueries'

const {Item: FlexItem} = Flex

const I18n = useI18nScope('rubrics-list-view')

export const ViewRubrics = () => {
  const navigate = useNavigate()
  const {accountId, courseId} = useParams()
  const isAccount = !!accountId
  const isCourse = !!courseId

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
      }

      curr.workflowState === 'active'
        ? prev.activeRubrics.push(rubric)
        : prev.archivedRubrics.push(rubric)
      return prev
    },
    {activeRubrics: [] as Rubric[], archivedRubrics: [] as Rubric[]}
  )

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
            value=""
            width="17"
            renderBeforeInput={<IconSearchLine inline={false} />}
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

      <View as="div" margin="large 0 0 0">
        <Heading level="h2" themeOverride={{h1FontWeight: 700}}>
          {I18n.t('Saved')}
        </Heading>
      </View>
      <View as="div" margin="medium 0" data-testid="saved-rubrics-table">
        <RubricTable rubrics={activeRubrics} />
      </View>

      <View as="div" margin="large 0 0 0">
        <Heading level="h2" themeOverride={{h1FontWeight: 700}}>
          {I18n.t('Archived')}
        </Heading>
      </View>
      <View as="div" margin="medium 0" data-testid="archived-rubrics-table">
        <RubricTable rubrics={archivedRubrics} />
      </View>
    </View>
  )
}
