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

import React from 'react'
import {type ePortfolio, ePortfolioPage, ePortfolioSection} from './types'
import {useQuery, type QueryFunction} from '@tanstack/react-query'
import {Alert} from '@instructure/ui-alerts'
import {useScope as createI18nScope} from '@canvas/i18n'
import PageList from './PageList'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Text} from '@instructure/ui-text'

const I18n = createI18nScope('eportfolio')

interface Props {
  readonly sectionId: number
  readonly portfolio: ePortfolio
  readonly isOwner: boolean
  readonly onUpdate: (json: ePortfolioPage) => void
}

type SectionQueryKey = readonly [string, number, number]

const fetchSection = async (portfolioId: number, sectionId: number): Promise<ePortfolioSection> => {
  const section = await doFetchApi<ePortfolioSection>({
    path: `/eportfolios/${portfolioId}/categories/${sectionId}`,
  })
  return section.json!
}

const queryFn: QueryFunction<ePortfolioSection, SectionQueryKey> = ({queryKey}) => {
  const [, portfolioId, sectionId] = queryKey
  return fetchSection(portfolioId, sectionId)
}

export default function PageContainer(props: Props) {
  const {data, isError, isLoading} = useQuery<
    ePortfolioSection,
    Error,
    ePortfolioSection,
    SectionQueryKey
  >({
    queryKey: ['portfolioSection', props.portfolio.id, props.sectionId],
    queryFn,
  })

  if (isError) {
    return (
      <Alert variant="error">
        <Text>{I18n.t('Failed to retrieve Page List.')}</Text>
      </Alert>
    )
  }

  const sectionName = data?.name ? data.name : ''
  return (
    <PageList
      isLoading={isLoading}
      sectionId={props.sectionId}
      sectionName={sectionName}
      portfolio={props.portfolio}
      isOwner={props.isOwner}
      onUpdate={props.onUpdate}
    />
  )
}
