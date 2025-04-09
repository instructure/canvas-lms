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

import doFetchApi from '@canvas/do-fetch-api-effect'
import {useQuery} from '@tanstack/react-query'
import {Portal} from '@instructure/ui-portal'
import PageContainer from './PageContainer'
import {ePortfolio, ePortfolioPage} from './types'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Alert} from '@instructure/ui-alerts'
import SectionContainer from './SectionContainer'

const I18n = createI18nScope('eportfolio')

interface Props {
  readonly portfolioId: number
  readonly sectionListNode: HTMLElement
  readonly pageListNode: HTMLElement
  readonly submissionNode: HTMLElement
  readonly onPageUpdate: (json: ePortfolioPage) => void
}

export default function PortfolioPortal(props: Props) {
  const isOwner = ENV.owner_view!
  const sectionId = ENV.category_id!

  const fetchPortfolio = async (): Promise<ePortfolio> => {
    const {json} = await doFetchApi<ePortfolio>({
      path: `/eportfolios/${props.portfolioId}`,
    })
    return json!
  }

  const {data, isLoading, error} = useQuery<ePortfolio>({
    queryKey: ['portfolio', props.portfolioId],
    queryFn: fetchPortfolio,
  })

  const renderPageList = () => {
    if (isLoading || data == null) {
      return <Spinner size="small" margin="0 auto" renderTitle={I18n.t('Loading page list')} />
    } else if (error) {
      return (
        <Alert variant="error" margin="0 auto">
          {I18n.t('Could not load page list')}
        </Alert>
      )
    }
    return (
      <PageContainer
        sectionId={sectionId}
        portfolio={data}
        isOwner={isOwner}
        onUpdate={props.onPageUpdate}
      />
    )
  }

  const renderSectionList = () => {
    if (isLoading || data == null) {
      return <Spinner size="small" margin="0 auto" renderTitle={I18n.t('Loading section list')} />
    } else if (error) {
      return (
        <Alert variant="error" margin="0 auto">
          {I18n.t('Could not load section list')}
        </Alert>
      )
    }
    return (
      <SectionContainer
        portfolio={data}
        isOwner={isOwner}
        sectionId={sectionId}
        sectionListNode={props.sectionListNode}
        submissionListNode={props.submissionNode}
      />
    )
  }

  return (
    <>
      <Portal open={true} mountNode={props.pageListNode}>
        {renderPageList()}
      </Portal>
      <Portal open={true} mountNode={props.sectionListNode}>
        {renderSectionList()}
      </Portal>
    </>
  )
}
