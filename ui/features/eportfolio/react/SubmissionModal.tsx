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

import {Modal} from '@instructure/ui-modal'
import React, {SyntheticEvent, useEffect, useRef, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {ePortfolioPage, ePortfolioSection, NamedSubmission} from './types'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Spinner} from '@instructure/ui-spinner'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {TextInput} from '@instructure/ui-text-input'
import {Flex} from '@instructure/ui-flex'
import {List} from '@instructure/ui-list'
import {Alert} from '@instructure/ui-alerts'
import {QueryFunctionContext, useInfiniteQuery} from '@tanstack/react-query'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {generatePageListKey} from './utils'
import {assignLocation} from '@canvas/util/globalUtils'

const I18n = createI18nScope('eportfolio')

const NAME_MAX_LENGTH = 255

interface Props {
  readonly submission: NamedSubmission | null
  readonly onClose: () => void
  readonly sections: ePortfolioSection[]
  readonly sectionId: number
  readonly portfolioId: number
  readonly isOpen: boolean
}

export default function SubmissionModal(props: Props) {
  const defaultSection = props.sections.find(s => s.id === props.sectionId)!
  const [loading, setLoading] = useState(false)
  const [section, setSection] = useState<ePortfolioSection>(defaultSection)
  const [name, setName] = useState({value: '', validation: ''})
  const observerRef = useRef<IntersectionObserver | null>(null)
  const nameRef = useRef<TextInput>(null)

  const handleCreatePage = async () => {
    if (name.value.length === 0) {
      if (name.validation === '') {
        setName({...name, validation: I18n.t('Page name is required')})
      }
      nameRef.current?.focus()
    } else if (name.value.length > NAME_MAX_LENGTH) {
      if (name.validation === '') {
        setName({...name, validation: I18n.t('Page name is too long')})
      }
      nameRef.current?.focus()
    } else if (section != null) {
      setLoading(true)
      // define sections for the page, with the first section describing the assignment and submission
      // and the second section containing the submission
      const body = {
        section_1: {
          section_type: 'rich_text',
          content: I18n.t('This is my %{assignmentName} submission for %{courseName}', {
            assignmentName: props.submission?.assignment_name,
            courseName: props.submission?.course_name,
          }),
        },
        section_2: {
          section_type: 'submission',
          submission_id: props.submission?.id,
        },
        eportfolio_entry: {
          name: name.value,
          eportfolio_category_id: section.id,
        },
        section_count: 2,
      }
      const {json} = await doFetchApi<ePortfolioPage>({
        path: `/eportfolios/${props.portfolioId}/entries`,
        method: 'POST',
        body,
      })
      // redirect
      assignLocation(json!.entry_url)
    }
  }

  const updateName = (_e: SyntheticEvent<Element, Event>, value: string) => {
    const updatedName = {...name, value}
    if (value.length > NAME_MAX_LENGTH) {
      updatedName.validation = I18n.t('Page name is too long')
    } else if (value.length === 0) {
      updatedName.validation = I18n.t('Page name is required')
    } else {
      updatedName.validation = ''
    }
    setName(updatedName)
  }

  const updateSection = (
    _event: SyntheticEvent<Element, Event>,
    data: {value?: string | number; id?: string},
  ) => {
    const selectedSection = props.sections.find(s => s.id.toString() === data.id)!
    setSection(selectedSection)
  }

  const fetchPages = async ({
    pageParam = '1',
  }: QueryFunctionContext): Promise<{json: ePortfolioPage[]; nextPage: string | null}> => {
    const params = {
      page: String(pageParam),
      per_page: '10',
    }
    const {json, link} = await doFetchApi<ePortfolioPage[]>({
      path: `/eportfolios/${props.portfolioId}/categories/${section.id}/pages`,
      params,
    })
    const nextPage = link?.next ? link.next.page : null
    if (json) {
      return {json, nextPage}
    }
    return {json: [], nextPage: null}
  }

  // useInfiniteQuery let's us leverage the cache from PageList.tsx
  const {data, isFetching, isFetchingNextPage, fetchNextPage, hasNextPage, isSuccess} =
    useInfiniteQuery({
      queryKey: generatePageListKey(section.id, props.portfolioId),
      queryFn: fetchPages,
      staleTime: 10 * 60 * 1000, // 10 minutes
      getNextPageParam: lastPage => lastPage.nextPage,
      initialPageParam: null,
    })

  useEffect(() => {
    if (props.submission) {
      setName({value: props.submission.assignment_name, validation: ''})
    }
  }, [props.submission])

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

  const renderModalBody = () => {
    if (loading) {
      return <Spinner margin="0 auto" renderTitle={I18n.t('Creating page')} />
    } else {
      return (
        <>
          <Flex direction="column" gap="small" margin="xx-small 0 medium">
            <Text size="small">
              {I18n.t(
                'To make a new page for this submission, select a section and enter the name for the new page.',
              )}
            </Text>
            <TextInput
              ref={nameRef}
              isRequired={true}
              renderLabel={I18n.t('Page name')}
              value={name.value}
              onChange={updateName}
              messages={name.validation === '' ? [] : [{type: 'newError', text: name.validation}]}
            />
          </Flex>
          <Flex alignItems="start" margin="small 0" gap="medium">
            <SimpleSelect
              data-testid="section-select"
              renderLabel={I18n.t('Section')}
              value={section.id}
              onChange={updateSection}
            >
              {props.sections.map(section => (
                <SimpleSelect.Option
                  data-testid={`option-${section.id}`}
                  key={section.id}
                  id={section.id.toString()}
                  value={section.id}
                >
                  {section.name}
                </SimpleSelect.Option>
              ))}
            </SimpleSelect>
            {renderPageList()}
          </Flex>
        </>
      )
    }
  }

  const renderPageList = () => {
    if (isFetching && !isFetchingNextPage) {
      return <Spinner margin="0 auto" size="small" renderTitle={I18n.t('Loading page list')} />
    } else if (!isSuccess || data == null) {
      return (
        <Alert variant="error" margin="0 auto">
          {I18n.t('Could not load page list')}
        </Alert>
      )
    } else {
      const allPages = data.pages.reduce<ePortfolioPage[]>(
        (acc: ePortfolioPage[], val: {json: ePortfolioPage[]}) => acc.concat(val.json),
        [],
      )
      return (
        <Flex.Item shouldGrow>
          <Text weight="bold" size="medium">
            {I18n.t("Pages in '%{sectionName}'", {sectionName: section.name})}
          </Text>
          <View overflowY="auto" maxHeight="150px" display="block">
            <List margin="small medium" isUnstyled>
              {allPages.map((page: ePortfolioPage, index: number) => (
                <List.Item key={page.id} elementRef={setTrigger(index, allPages.length)}>
                  {page.name}
                </List.Item>
              ))}
            </List>
            {isFetchingNextPage ? (
              <Spinner size="small" renderTitle={I18n.t('Loading page list')} />
            ) : null}
          </View>
        </Flex.Item>
      )
    }
  }

  return (
    <Modal
      label={I18n.t('Add Page for Submission Modal')}
      open={props.isOpen}
      as="form"
      noValidate={true}
      data-testid="create-page-modal"
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={props.onClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{I18n.t('Add Page for Submission')}</Heading>
      </Modal.Header>
      <Modal.Body>{renderModalBody()}</Modal.Body>
      <Modal.Footer>
        <Button margin="0 small" onClick={props.onClose} disabled={loading}>
          {I18n.t('Cancel')}
        </Button>
        <Button
          data-testid={'create-page-button'}
          color="primary"
          onClick={handleCreatePage}
          disabled={loading}
        >
          {I18n.t('Create Page')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
