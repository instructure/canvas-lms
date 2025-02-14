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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {raw} from '@instructure/html-escape'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Select} from '@instructure/ui-select'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Tag} from '@instructure/ui-tag'
import {useRef, useState, type MouseEvent} from 'react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Spinner} from '@instructure/ui-spinner'
import {Avatar} from '@instructure/ui-avatar'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('link_to_students')

interface Enrollment {
  observed_user: Observee
}

export interface Observee {
  id: string
  name: string
  avatar_url: string
  enrollments?: Array<{
    id: string
    type: string
    course_section_id: string
    associated_user_id: string
  }>
}

type Observer = Observee

interface Course {
  id: string
  name: string
}

export interface LinkToStudentsProps {
  observer: Observer
  initialObservees: Array<Observee>
  course: Course
  onClose: () => void
  onSubmit: (addedEnrollments: Array<Enrollment>, removedEnrollments: Array<Enrollment>) => void
}

const LinkToStudents = ({
  observer,
  initialObservees,
  course,
  onClose,
  onSubmit,
}: LinkToStudentsProps) => {
  const inputRef = useRef<HTMLInputElement | null>(null)
  const [inputValue, setInputValue] = useState('')
  const [selectedObservees, setSelectedObservees] = useState<Array<Observee>>(initialObservees)
  const [availableObservees, setAvailableObservees] = useState<Array<Observee>>([])
  const [highlightedOptionId, setHighlightedOptionId] = useState<string | null>(null)
  const [nextPageCursor, setNextPageCursor] = useState<string>()
  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [isLoadingNextPage, setIsLoadingNextPage] = useState(false)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const abortControllerRef = useRef<AbortController | null>(null)
  const intersectionObserverRef = useRef<IntersectionObserver | null>(null)
  const title = I18n.t('Link to Students')
  const updateButtonText = isSubmitting ? I18n.t('Updating...') : I18n.t('Update')
  const cancelButtonText = I18n.t('Cancel')
  const selectLabel = I18n.t('Observee select')

  const fetchObservees = async ({
    searchTerm,
    page,
    skipAbort,
  }: {searchTerm: string; page?: string; skipAbort: boolean}) => {
    const context = `course_${course.id}_students`
    const observeeIdsToExclude = [observer.id, ...selectedObservees.map(observee => observee.id)]

    if (abortControllerRef.current && !skipAbort) {
      abortControllerRef.current.abort()
    }

    abortControllerRef.current = new AbortController()

    try {
      const {json = [], link} = await doFetchApi<Array<Observee>>({
        path: '/search/recipients',
        params: {
          context,
          page,
          exclude: observeeIdsToExclude,
          per_page: 100,
          types: ['user'],
          type: 'user',
          skip_visibility_checks: true,
          synthetic_contexts: '1',
          search: searchTerm,
        },
        signal: abortControllerRef.current.signal,
      })

      return {json: json!, nextPage: link?.next?.page}
    } catch {
      return {json: [] as Array<Observee>, nextPage: undefined}
    }
  }

  const getUserWithEnrollments = async (userId: string) => {
    const {json} = await doFetchApi<Observee>({
      path: `/api/v1/courses/${course.id}/users/${userId}`,
      method: 'GET',
      params: {
        include: ['enrollments'],
      },
    })

    return json!
  }

  const linkObservee = async (observeeId: string) => {
    // Needs to be refetched because the enrollments are missing from the original observee object
    const observeeUser = await getUserWithEnrollments(observeeId)

    const createLinkPromises = (observeeUser.enrollments ?? []).map(async ({course_section_id}) => {
      const {json} = await doFetchApi<Enrollment>({
        path: `/api/v1/sections/${course_section_id}/enrollments`,
        method: 'POST',
        body: {
          enrollment: {
            user_id: observer.id,
            associated_user_id: observeeUser.id,
            type: 'ObserverEnrollment',
          },
        },
      })

      return json!
    })

    const enrollments = (await Promise.all(createLinkPromises)).map(enrollment => {
      enrollment.observed_user = observeeUser

      return enrollment
    })

    return enrollments
  }

  const removeObserveeLink = async (enrollmentId: string) => {
    const {json} = await doFetchApi<{enrollment: Enrollment}>({
      path: `/courses/${course.id}/unenroll/${enrollmentId}`,
      method: 'DELETE',
    })

    return json!.enrollment
  }

  const updateSearchDropdown = async ({searchTerm, page}: {searchTerm: string; page?: string}) => {
    const isFetchingNextPage = page !== undefined

    if (isFetchingNextPage) {
      setIsLoadingNextPage(true)
    } else {
      setIsLoading(true)
    }

    const {json: filteredObservees, nextPage} = await fetchObservees({
      searchTerm,
      page,
      skipAbort: isFetchingNextPage,
    })

    setNextPageCursor(nextPage)
    setAvailableObservees(prevAvailableObservees =>
      isFetchingNextPage ? [...prevAvailableObservees, ...filteredObservees] : filteredObservees,
    )
    setHighlightedOptionId(prevHighlightedOptionId =>
      isFetchingNextPage
        ? prevHighlightedOptionId
        : filteredObservees.length > 0
          ? filteredObservees[0].id
          : null,
    )
    setIsLoading(false)
    setIsLoadingNextPage(false)
  }

  const handleShowOptions = async () => {
    setIsShowingOptions(true)

    updateSearchDropdown({searchTerm: inputValue})
  }

  const handleHideOptions = () => {
    setIsShowingOptions(false)
  }

  const handleBlur = () => {
    setHighlightedOptionId(null)
  }

  const handleHighlightOption = (id?: string) => {
    const foundObservee = availableObservees.find(observee => observee.id === id)

    if (!foundObservee) {
      return
    }

    setHighlightedOptionId(id!)
  }

  const handleSelectOption = (id?: string) => {
    const foundObservee = availableObservees.find(observee => observee.id === id)

    if (!foundObservee) {
      return
    }

    setSelectedObservees([...selectedObservees, foundObservee])
    setHighlightedOptionId(null)
    setAvailableObservees([])
    setInputValue('')
    setIsShowingOptions(false)
  }

  const handleInputChange = async (value: string) => {
    setInputValue(value)
    setIsShowingOptions(true)

    updateSearchDropdown({searchTerm: value})
  }

  const handleKeyDown = (event: {keyCode: number}) => {
    const isBackspaceKeyPressed = event.keyCode === 8
    if (isBackspaceKeyPressed && inputValue === '' && selectedObservees.length > 0) {
      setSelectedObservees(selectedObservees.slice(0, -1))
      setIsShowingOptions(false)
    }
  }

  const handleFormSubmit = async (event: React.SyntheticEvent) => {
    event.preventDefault()

    const initialObserveeIds = new Set(initialObservees.map(observee => observee.id))
    const selectedObserveeIds = new Set(selectedObservees.map(observee => observee.id))
    const observeeIdsToAdd = selectedObserveeIds.difference(initialObserveeIds)
    const observeeIdsToRemove = initialObserveeIds.difference(selectedObserveeIds)
    const observeeEnrollmentIdsToRemove = (observer.enrollments ?? [])
      .filter(enrollment => observeeIdsToRemove.has(enrollment.associated_user_id))
      .map(enrollment => enrollment.id)

    try {
      setIsSubmitting(true)

      const [addedEnrollments, removedEnrollments] = await Promise.all([
        Promise.all(Array.from(observeeIdsToAdd.values()).map(linkObservee)),
        Promise.all(observeeEnrollmentIdsToRemove.map(removeObserveeLink)),
      ])

      onSubmit(addedEnrollments.flat(), removedEnrollments)
      showFlashSuccess(I18n.t('Student links successfully updated.'))()
    } catch (error: any) {
      const isJsonResponse = error?.response?.headers
        ?.get('Content-Type')
        ?.includes('application/json')
      const errorResponse = isJsonResponse && (await error?.response?.json())

      const responseMessage = errorResponse.errors?.associated_user_id?.[0]?.message
      if (responseMessage === 'Cannot observe observer observing self') {
        showFlashError(
          I18n.t(
            'Cannot observe user with another user that is being observed by the current user.',
          ),
        )()
      } else {
        showFlashError(
          I18n.t("Something went wrong updating the user's student links. Please try again later."),
        )()
      }
    } finally {
      setIsSubmitting(false)
      onClose()
    }
  }

  const dismissTag = (event: MouseEvent, observeeToRemove: Observee) => {
    event.stopPropagation()
    event.preventDefault()

    setIsShowingOptions(false)
    setSelectedObservees(selectedObservees.filter(observee => observee.id !== observeeToRemove.id))
    setHighlightedOptionId(null)
    inputRef.current?.focus()
  }

  const tags = selectedObservees.map((observee, index) => {
    const {id, name: oberveeName} = observee

    return (
      <Tag
        key={id}
        dismissible
        title={I18n.t(`Remove %{oberveeName}`, {oberveeName})}
        data-testid={`observee-tag-${id}`}
        text={oberveeName}
        margin={index > 0 ? 'xxx-small 0 xxx-small xx-small' : 'xxx-small 0'}
        onClick={event => dismissTag(event, observee)}
      />
    )
  })

  const selectedObserveeIds = selectedObservees.map(observee => observee.id)
  const availableObserveesWithoutTheSelectedOnes = availableObservees.filter(
    ({id}) => !selectedObserveeIds.includes(id),
  )
  const cleanUpOldTrigger = () => {
    if (intersectionObserverRef.current === null) {
      return
    }
    intersectionObserverRef.current.disconnect()
    intersectionObserverRef.current = null
  }
  const isNextPageTrigger = (itemIndex: number) =>
    itemIndex === availableObservees.length - 1 && nextPageCursor
  const setNextPageTrigger = (itemIndex: number, ref: Element | null) => {
    if (!isNextPageTrigger(itemIndex) || !ref) {
      return
    }

    intersectionObserverRef.current = new IntersectionObserver(function (entries) {
      if (entries[0].isIntersecting) {
        updateSearchDropdown({searchTerm: inputValue, page: nextPageCursor})
        cleanUpOldTrigger()
      }
    })
    intersectionObserverRef.current.observe(ref)
  }
  const spinnerOption = (
    <Select.Option id="empty-option" key="empty-option" isDisabled={true}>
      <Spinner renderTitle="Loading" size="x-small" />
    </Select.Option>
  )
  let selectOptions = null

  if (isLoading) {
    selectOptions = spinnerOption
  } else if (availableObserveesWithoutTheSelectedOnes.length) {
    selectOptions = availableObserveesWithoutTheSelectedOnes.map((observee, index) => {
      const isHighlighted = highlightedOptionId === observee.id

      return (
        <Select.Option id={observee.id} key={observee.id} isHighlighted={isHighlighted}>
          <Flex gap="small" elementRef={ref => setNextPageTrigger(index, ref)}>
            <Avatar name={observee.name} src={observee.avatar_url} size="x-small" />
            <Flex direction="column">
              <Text weight="bold">{observee.name}</Text>
              <Text size="small" color={isHighlighted ? 'secondary-inverse' : 'secondary'}>
                {course.name}
              </Text>
            </Flex>
          </Flex>
        </Select.Option>
      )
    })

    if (isLoadingNextPage) {
      selectOptions.push(spinnerOption)
    }
  } else {
    selectOptions = (
      <Select.Option id="empty-option" key="empty-option" isDisabled={true}>
        {I18n.t('No results')}
      </Select.Option>
    )
  }

  return (
    <Modal
      as="form"
      label={title}
      size="small"
      open={true}
      shouldCloseOnDocumentClick={false}
      onDismiss={onClose}
      onSubmit={handleFormSubmit}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{title}</Heading>
      </Modal.Header>
      <Modal.Body>
        <Flex direction="column" gap="small">
          <Text>
            {I18n.t(
              "When an observer is linked to a student, they have access to that student's grades and course interactions.",
            )}
          </Text>
          <Text
            dangerouslySetInnerHTML={{
              __html: raw(
                I18n.t(
                  "To link the course observer *%{observerName}* to a student, start typing the student's name below to find them and then click Update.",
                  {wrapper: '<b>$1</b>', observerName: observer.name},
                ),
              ),
            }}
          />
          <Select
            aria-label={selectLabel}
            renderLabel={<ScreenReaderContent>{selectLabel}</ScreenReaderContent>}
            assistiveText={I18n.t(
              'Type or use arrow keys to navigate options. Multiple selections allowed.',
            )}
            inputValue={inputValue}
            isShowingOptions={isShowingOptions}
            inputRef={ref => (inputRef.current = ref)}
            onBlur={handleBlur}
            onInputChange={(_event, value) => handleInputChange(value)}
            onRequestShowOptions={handleShowOptions}
            onRequestHideOptions={handleHideOptions}
            onRequestHighlightOption={(_event, {id}) => handleHighlightOption(id)}
            onRequestSelectOption={(_event, {id}) => handleSelectOption(id)}
            onKeyDown={handleKeyDown}
            renderBeforeInput={selectedObservees.length > 0 ? tags : null}
          >
            {selectOptions}
          </Select>
        </Flex>
      </Modal.Body>
      <Modal.Footer>
        <Button type="button" color="secondary" aria-label={cancelButtonText} onClick={onClose}>
          {cancelButtonText}
        </Button>
        <Button
          type="submit"
          color="primary"
          aria-label={updateButtonText}
          disabled={isSubmitting}
          margin="0 0 0 small"
        >
          {updateButtonText}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export default LinkToStudents
