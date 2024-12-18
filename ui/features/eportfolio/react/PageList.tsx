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

import {Flex} from '@instructure/ui-flex'
import React, {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useQuery} from '@canvas/query'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Spinner} from '@instructure/ui-spinner'
import {Alert} from '@instructure/ui-alerts'
import {Text} from '@instructure/ui-text'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Link} from '@instructure/ui-link'
import {Table} from '@instructure/ui-table'
import {
  IconMoreLine,
  IconAddLine,
  IconTrashLine,
  IconTextLine,
  IconSortLine,
} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import type {ePortfolioSection, ePortfolio, ePortfolioPage} from './types'
import PageEditModal from './PageEditModal'

const I18n = createI18nScope('eportfolio')

interface Props {
  readonly sectionId: number
  readonly portfolio: ePortfolio
  readonly isOwner: boolean
  readonly onUpdate: (json: ePortfolioPage) => void
}

type PageData = {
  section: ePortfolioSection
  pages: ePortfolioPage[]
}

const fetchSectionAndPages = async (portfolioId: number, sectionId: number): Promise<PageData> => {
  const section = await doFetchApi<ePortfolioSection>({
    path: `/eportfolios/${portfolioId}/categories/${sectionId}`,
  })
  const pages = await doFetchApi<ePortfolioPage[]>({
    path: `/eportfolios/${portfolioId}/categories/${sectionId}/pages`,
  })
  if (section.json && pages.json) {
    return {section: section.json, pages: pages.json}
  } else {
    return {} as PageData
  }
}

function PageList(props: Props) {
  const [modalType, setModalType] = useState('')
  const [selectedPage, setSelectedPage] = useState<ePortfolioPage | null>(null)

  const {data, isError, isLoading, refetch} = useQuery<PageData>({
    queryFn: () => fetchSectionAndPages(props.portfolio.id, props.sectionId),
    queryKey: ['portfolioPageList', props.portfolio.id, props.sectionId],
  })

  const onConfirm = (json?: undefined | ePortfolioPage) => {
    if (json) {
      props.onUpdate(json)
    }
    setModalType('')
    setSelectedPage(null)
    refetch()
  }

  const onCancel = () => {
    setModalType('')
    setSelectedPage(null)
  }

  const onMenuSelect = (page: ePortfolioPage, type: string) => {
    if (page != null) {
      setSelectedPage(page)
    }
    setModalType(type)
  }

  const renderModal = (pages: ePortfolioPage[]) => {
    if (modalType !== '') {
      return (
        <PageEditModal
          modalType={modalType}
          portfolio={props.portfolio}
          page={selectedPage}
          sectionId={props.sectionId}
          pageList={pages}
          onConfirm={onConfirm}
          onCancel={onCancel}
        />
      )
    }
  }

  const renderPageRow = (page: ePortfolioPage) => {
    const options = [
      <Menu.Item
        key="rename"
        data-testid="rename-menu-option"
        onClick={() => onMenuSelect(page, 'rename')}
      >
        <Flex gap="x-small" direction="row">
          <IconTextLine />
          <Text>{I18n.t('Rename')}</Text>
        </Flex>
      </Menu.Item>,
    ]
    if (data && data.pages.length > 1) {
      options.push(
        <Menu.Item
          key="move"
          data-testid="move-menu-option"
          onClick={() => onMenuSelect(page, 'move')}
        >
          <Flex gap="x-small" direction="row">
            <IconSortLine />
            {I18n.t('Move to...')}
          </Flex>
        </Menu.Item>
      )
      options.push(
        <Menu.Item
          key="delete"
          data-testid="delete-menu-option"
          onClick={() => onMenuSelect(page, 'delete')}
        >
          <Flex gap="x-small" direction="row">
            <IconTrashLine />
            {I18n.t('Delete')}
          </Flex>
        </Menu.Item>
      )
    }
    return (
      <Table.Row key={page.id}>
        <Table.Cell>
          <Link href={page.entry_url}>
            <Text>{page.name}</Text>
          </Link>
        </Table.Cell>
        <Table.Cell>
          {props.isOwner ? (
            <Menu
              trigger={
                <IconButton
                  withBorder={false}
                  data-testid={`${page.id}-menu`}
                  screenReaderLabel={I18n.t('Page options for %{page}', {page: page.name})}
                  size="small"
                >
                  <IconMoreLine />
                </IconButton>
              }
            >
              {options}
            </Menu>
          ) : null}
        </Table.Cell>
      </Table.Row>
    )
  }

  if (isError) {
    return <Alert variant="error">{I18n.t('Failed to load ePortfolio pages')}</Alert>
  } else if (isLoading) {
    return <Spinner size="medium" renderTitle={I18n.t('Loading ePortfolio pages')} />
  } else {
    return (
      <Flex direction="column">
        <Text weight="bold" size="large">
          {data.section.name}
        </Text>
        <Text>{I18n.t('Pages')}</Text>
        <Table margin="x-small 0" caption={I18n.t('List of pages')}>
          <Table.Body>
            {data.pages.map((page: ePortfolioPage) => {
              return renderPageRow(page)
            })}
          </Table.Body>
        </Table>
        {props.isOwner ? (
          <>
            {renderModal(data.pages)}
            <Button
              margin="x-small 0"
              data-testid="add-page-button"
              renderIcon={<IconAddLine />}
              textAlign="start"
              onClick={() => setModalType('add')}
            >
              {I18n.t('Add Page')}
            </Button>
          </>
        ) : null}
      </Flex>
    )
  }
}
export default PageList
