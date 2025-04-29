/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {Portal} from '@instructure/ui-portal'
import React from 'react'
import SectionList from './SectionList'
import {QueryFunctionContext, useQuery} from '@tanstack/react-query'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {ePortfolioSection} from './types'
import {Spinner} from '@instructure/ui-spinner'
import {Alert} from '@instructure/ui-alerts'
import {useScope as createI18nScope} from '@canvas/i18n'
import SubmissionList from './SubmissionList'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('eportfolio')

interface Props {
  portfolio: any
  isOwner: boolean
  sectionId: number
  sectionListNode: HTMLElement
  submissionListNode: HTMLElement
}

const fetchSections = async (portfolio_id: number): Promise<ePortfolioSection[]> => {
  const {json} = await doFetchApi<ePortfolioSection[]>({
    path: `/eportfolios/${portfolio_id}/categories`,
  })
  return json!
}

const queryFn = ({queryKey}: QueryFunctionContext<[string, number]>) => {
  const [, portfolioId] = queryKey
  return fetchSections(portfolioId)
}

export default function SectionContainer(props: Props) {
  const {data, isLoading, isError, refetch} = useQuery({
    queryKey: ['portfolioSectionList', props.portfolio.id],
    queryFn,
  })

  const renderSectionList = () => {
    if (isLoading || data == null) {
      return <Spinner margin="0 auto" renderTitle={I18n.t('Loading section list')} />
    } else if (isError) {
      return (
        <Alert variant="error" margin="0 auto">
          {I18n.t('Could not load section list')}
        </Alert>
      )
    }
    return (
      <SectionList
        isOwner={props.isOwner}
        portfolio={props.portfolio}
        sections={data}
        onConfirm={refetch}
      />
    )
  }

  const renderSubmissionList = () => {
    if (isLoading || data == null) {
      return (
        <View
          margin="small"
          as="div"
          textAlign="center"
          borderRadius="medium"
          borderWidth="small"
          maxHeight="300px"
          overflowY="auto"
        >
          <Spinner margin="0 auto" renderTitle={I18n.t('Loading section list')} />
        </View>
      )
    } else if (isError) {
      return (
        <Alert variant="error" margin="0 auto">
          {I18n.t('Could not load section list')}
        </Alert>
      )
    }
    return (
      <SubmissionList
        sections={data}
        portfolioId={props.portfolio.id}
        sectionId={props.sectionId}
      />
    )
  }

  // don't render at all if node is undefined
  return (
    <>
      {props.sectionListNode && (
        <Portal mountNode={props.sectionListNode} open={true}>
          {renderSectionList()}
        </Portal>
      )}
      {props.submissionListNode && (
        <Portal mountNode={props.submissionListNode} open={true}>
          {renderSubmissionList()}
        </Portal>
      )}
    </>
  )
}
