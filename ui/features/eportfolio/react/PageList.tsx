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
import React, {useState, useRef} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useInfiniteQuery, type QueryFunctionContext} from '@tanstack/react-query'
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
import type {ePortfolio, ePortfolioPage} from './types'
import PageEditModal from './PageEditModal'
import {View} from '@instructure/ui-view'
import {generatePageListKey} from './utils'

const I18n = createI18nScope('eportfolio')

interface Props {
  readonly sectionId: number
  readonly sectionName: string
  readonly portfolio: ePortfolio
  readonly isOwner: boolean
  readonly onUpdate: (json: ePortfolioPage) => void
  readonly isLoading: boolean
}

function PageList(props: Props) {
  const [modalType, setModalType] = useState('')
  const [selectedPage, setSelectedPage] = useState<ePortfolioPage | null>(null)
  const observerRef = useRef<IntersectionObserver | null>(null)

  const fetchPages = async ({
    pageParam = '1',
  }: QueryFunctionContext): Promise<{json: ePortfolioPage[]; nextPage: string | null}> => {
    const params = {
      page: String(pageParam),
      per_page: '10',
    }
    const {json, link} = await doFetchApi<ePortfolioPage[]>({
      path: `/eportfolios/${props.portfolio.id}/categories/${props.sectionId}/pages`,
      params,
      fetchOpts: {
        cache: 'no-store',
      },
    })
    const nextPage = link?.next ? link.next.page : null
    if (json) {
      return {json, nextPage}
    }
    return {json: [], nextPage: null}
  }

  const {data, refetch, fetchNextPage, isFetching, isFetchingNextPage, hasNextPage, isSuccess} =
    useInfiniteQuery({
      queryKey: generatePageListKey(props.sectionId, props.portfolio.id),
      queryFn: fetchPages,
      staleTime: 10 * 60 * 1000, // 10 minutes
      getNextPageParam: lastPage => lastPage.nextPage,
      initialPageParam: '1',
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

  function clearPageLoadTrigger() {
    if (observerRef.current === null) return
    observerRef.current.disconnect()
    observerRef.current = null
  }

  function setPageLoadTrigger(ref: Element | null) {
    if (ref === null) return
    clearPageLoadTrigger()
    observerRef.current = new IntersectionObserver(function (entries) {
      if (entries[0].isIntersecting) {
        fetchNextPage()
        clearPageLoadTrigger()
      }
    })
    observerRef.current.observe(ref)
  }

  const isTriggerRow = (row: number, numOfPages: number) =>
    row === numOfPages - 1 && !!hasNextPage && !isFetching
  const setTrigger = (row: number, numOfPages: number) =>
    isTriggerRow(row, numOfPages) ? (ref: Element | null) => setPageLoadTrigger(ref) : undefined

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

  const renderPageRow = (page: ePortfolioPage, index: number, pageLength: number) => {
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
    if (pageLength > 1) {
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
        </Menu.Item>,
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
        </Menu.Item>,
      )
    }
    return (
      <Table.Row key={page.id}>
        <Table.Cell>
          <Link href={page.entry_url}>
            <Text elementRef={setTrigger(index, pageLength)}>{page.name}</Text>
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

  if ((isFetching && !isFetchingNextPage) || props.isLoading) {
    return <Spinner size="medium" renderTitle={I18n.t('Loading ePortfolio pages')} />
  } else if (!isSuccess) {
    return <Alert variant="error">{I18n.t('Failed to load ePortfolio pages')}</Alert>
  } else {
    const allPages = data.pages.reduce<ePortfolioPage[]>((acc, val) => acc.concat(val.json), [])
    return (
      <Flex direction="column" gap="xx-small">
        <Text weight="bold" size="large">
          {props.sectionName}
        </Text>
        <Text>{I18n.t('Pages')}</Text>
        <View display="block" maxHeight="400px" margin="0" overflowY="auto">
          <Table caption={I18n.t('List of pages')}>
            <Table.Body>
              {allPages.map((page: ePortfolioPage, index: number) => {
                return renderPageRow(page, index, allPages.length)
              })}
            </Table.Body>
          </Table>
          {isFetchingNextPage ? (
            <Spinner size="small" renderTitle={I18n.t('Loading ePortfolio pages')} />
          ) : null}
        </View>
        {props.isOwner ? (
          <>
            {renderModal(allPages)}
            <Button
              margin="0 0 xx-small 0"
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
