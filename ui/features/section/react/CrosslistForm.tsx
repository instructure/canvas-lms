/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import React, {useReducer, useRef} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {IconOffLine} from '@instructure/ui-icons'
import {Alert} from '@instructure/ui-alerts'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {addFlashNoticeForNextPage} from '@canvas/rails-flash-notifications'
import CanvasAsyncSelect from '@canvas/instui-bindings/react/AsyncSelect'
import {useDebouncedCallback} from 'use-debounce'

const I18n = createI18nScope('section')

interface CourseOption {
  id: string
  label: string
  sis_id?: string
  term: string
}

interface ConfirmCrosslistResponse {
  allowed: boolean
  course?: {
    id: string
    name: string
    sis_source_id?: string
  }
  account?: {
    name: string
  }
}

interface CrosslistFormProps {
  sectionId: string
  isAlreadyCrosslisted: boolean
  manageableCoursesUrl: string
  confirmCrosslistUrl: string
  crosslistUrl: string
}

interface SelectedCourse {
  name: string
  sisId?: string
  accountName?: string
}

interface State {
  isOpen: boolean
  isSubmitting: boolean
  isConfirming: boolean
  courseSearchValue: string
  courseIdValue: string
  courseIdError: string | null
  courseSearchError: string | null
  confirmedCourseId: string | null
  selectedCourse: SelectedCourse | null
  isLoadingCourses: boolean
  courseOptions: CourseOption[]
  firstUse: boolean
  submissionError: string | null
}

type Action =
  | {type: 'OPEN_MODAL'}
  | {type: 'CLOSE_MODAL'}
  | {type: 'COURSE_SEARCH_CHANGED'; payload: string}
  | {type: 'COURSE_ID_CHANGED'; payload: string}
  | {type: 'CONFIRM_START'; payload: {courseName: string}}
  | {type: 'CONFIRM_SUCCESS'; payload: {course: SelectedCourse; courseId: string}}
  | {type: 'CONFIRM_ERROR'; payload: {error: string; field: 'search' | 'id'}}
  | {type: 'SUBMIT_START'}
  | {type: 'SUBMIT_ERROR'}
  | {type: 'SUBMIT_VALIDATION_ERROR'; payload: string}
  | {type: 'SEARCH_START'}
  | {type: 'SEARCH_SUCCESS'; payload: CourseOption[]}
  | {type: 'SEARCH_ERROR'}
  | {type: 'SEARCH_FIELD_BLURRED'}

const initialState: State = {
  isOpen: false,
  isSubmitting: false,
  isConfirming: false,
  courseSearchValue: '',
  courseIdValue: '',
  courseIdError: null,
  courseSearchError: null,
  confirmedCourseId: null,
  selectedCourse: null,
  isLoadingCourses: false,
  courseOptions: [],
  firstUse: true,
  submissionError: null,
}

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'OPEN_MODAL':
      return {...state, isOpen: true}

    case 'CLOSE_MODAL':
      return {...initialState, isOpen: false}

    case 'COURSE_SEARCH_CHANGED':
      return {
        ...state,
        courseSearchValue: action.payload,
        courseIdValue: '',
        courseIdError: null,
        courseSearchError: null,
        selectedCourse: null,
        confirmedCourseId: null,
        submissionError: null,
      }

    case 'COURSE_ID_CHANGED':
      return {
        ...state,
        courseIdValue: action.payload,
        courseSearchValue: '',
        courseIdError: null,
        courseSearchError: null,
        selectedCourse: null,
        confirmedCourseId: null,
        courseOptions: [],
        submissionError: null,
      }

    case 'CONFIRM_START':
      return {
        ...state,
        courseSearchValue: action.payload.courseName,
        firstUse: true,
        isConfirming: true,
        courseIdError: null,
        courseSearchError: null,
        selectedCourse: {name: action.payload.courseName},
      }

    case 'CONFIRM_SUCCESS':
      return {
        ...state,
        isConfirming: false,
        selectedCourse: action.payload.course,
        confirmedCourseId: action.payload.courseId,
        submissionError: null,
      }

    case 'CONFIRM_ERROR':
      return {
        ...state,
        isConfirming: false,
        selectedCourse: null,
        confirmedCourseId: null,
        courseIdError: action.payload.field === 'id' ? action.payload.error : null,
        courseSearchError: action.payload.field === 'search' ? action.payload.error : null,
      }

    case 'SUBMIT_START':
      return {...state, isSubmitting: true}

    case 'SUBMIT_ERROR':
      return {...state, isSubmitting: false}

    case 'SUBMIT_VALIDATION_ERROR':
      return {...state, submissionError: action.payload}

    case 'SEARCH_START':
      return {...state, firstUse: false, isLoadingCourses: true}

    case 'SEARCH_SUCCESS':
      return {...state, isLoadingCourses: false, courseOptions: action.payload}

    case 'SEARCH_ERROR':
      return {...state, isLoadingCourses: false, courseOptions: []}

    case 'SEARCH_FIELD_BLURRED':
      return {...state, firstUse: false}

    default:
      return state
  }
}

export default function CrosslistForm({
  sectionId,
  isAlreadyCrosslisted,
  manageableCoursesUrl,
  confirmCrosslistUrl,
  crosslistUrl,
}: CrosslistFormProps): React.JSX.Element {
  const [state, dispatch] = useReducer(reducer, initialState)
  const lastConfirmedInputRef = useRef<string | null>(null)

  const buttonLabel = isAlreadyCrosslisted
    ? I18n.t('Re-Cross-List this Section')
    : I18n.t('Cross-List this Section')

  const searchCourses = useDebouncedCallback(async (searchTerm: string) => {
    const trimmedTerm = searchTerm.trim()

    // Don't search if less than 3 characters
    if (trimmedTerm.length < 3) {
      dispatch({type: 'SEARCH_ERROR'})
      return
    }

    dispatch({type: 'SEARCH_START'})
    try {
      const {json} = await doFetchApi<CourseOption[]>({
        path: manageableCoursesUrl,
        params: {term: trimmedTerm},
      })
      dispatch({type: 'SEARCH_SUCCESS', payload: json || []})
    } catch {
      dispatch({type: 'SEARCH_ERROR'})
    }
  }, 500)

  function getSearchMessages(): Array<{type: 'hint' | 'newError'; text: string}> {
    const messages: Array<{type: 'hint' | 'newError'; text: string}> = []

    // If there's an error from the reducer, be sure to show it
    if (state.courseSearchError) messages.push({type: 'newError', text: state.courseSearchError})

    if (state.courseSearchValue.trim().length < 3) {
      messages.push({
        type: state.firstUse ? 'hint' : 'newError',
        text: I18n.t('Enter at least 3 characters to search'),
      })
    }

    return messages
  }

  function handleOpen() {
    lastConfirmedInputRef.current = null
    dispatch({type: 'OPEN_MODAL'})
  }

  function handleClose() {
    if (!state.isSubmitting) {
      dispatch({type: 'CLOSE_MODAL'})
    }
  }

  async function confirmCourse(courseId: string, courseName?: string) {
    if (!courseId.trim()) return

    // Don't confirm the same value twice
    if (courseId === lastConfirmedInputRef.current) return

    const displayName = courseName || I18n.t('Course ID "%{course_id}"', {course_id: courseId})
    dispatch({type: 'CONFIRM_START', payload: {courseName: displayName}})

    // Track what we're confirming
    lastConfirmedInputRef.current = courseId

    // Build the API URL (replace :id placeholder)
    const path = confirmCrosslistUrl.replace(':id', courseId)

    try {
      const {json} = await doFetchApi<ConfirmCrosslistResponse>({path})

      // If we don't get back a JSON, something terrible has happened
      if (!json) throw new Error('Received empty response from confirmation API')

      if (json.allowed) {
        // Success - update state with confirmed course
        dispatch({
          type: 'CONFIRM_SUCCESS',
          payload: {
            course: {
              name: json.course!.name,
              sisId: json.course!.sis_source_id,
              accountName: json.account?.name,
            },
            courseId: json.course!.id,
          },
        })
      } else {
        // Not allowed - show error in appropriate field
        const errorMsg = I18n.t('%{course_name} not authorized for cross-listing', {
          course_name: displayName,
        })
        dispatch({
          type: 'CONFIRM_ERROR',
          payload: {
            error: errorMsg,
            field: courseName ? 'search' : 'id',
          },
        })
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : I18n.t('Unknown error')
      dispatch({
        type: 'CONFIRM_ERROR',
        payload: {
          error: I18n.t('Confirmation Failed: %{message}', {message}),
          field: courseName ? 'search' : 'id',
        },
      })
    }
  }

  async function handleSubmit() {
    // Validate that a course has been selected
    if (!state.confirmedCourseId) {
      dispatch({
        type: 'SUBMIT_VALIDATION_ERROR',
        payload: I18n.t('Please select and confirm a course before submitting.'),
      })
      return
    }

    dispatch({type: 'SUBMIT_START'})

    try {
      await doFetchApi({
        path: crosslistUrl,
        method: 'POST',
        body: {new_course_id: state.confirmedCourseId},
      })

      // On success, redirect to the section page in the NEW course and arrange for a success flash there
      addFlashNoticeForNextPage('success', I18n.t('Section successfully cross-listed!'))
      window.location.href = `/courses/${state.confirmedCourseId}/sections/${sectionId}`
    } catch (error) {
      // On error, reset submitting state and show error message
      dispatch({type: 'SUBMIT_ERROR'})
      showFlashError(I18n.t('Failed to cross-list section'))(error as Error)
    }
  }

  return (
    <>
      <Button
        onClick={handleOpen}
        display="block"
        textAlign="start"
        renderIcon={<IconOffLine />}
        margin="xx-small 0"
        data-testid="crosslist-trigger-button"
      >
        {buttonLabel}
      </Button>

      <Modal
        open={state.isOpen}
        onDismiss={handleClose}
        size="small"
        label={buttonLabel}
        data-testid="crosslist-modal"
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="small"
            onClick={handleClose}
            screenReaderLabel={I18n.t('Close')}
            disabled={state.isSubmitting}
          />
          <Heading>{I18n.t('Cross-List Section')}</Heading>
        </Modal.Header>
        <Modal.Body>
          <View as="div" margin="0 0 medium 0">
            <Text as="p">
              {I18n.t(
                'Cross-listing allows you to create a section in one account and then move it to a course on a different account. To cross-list this course, you’ll need to find the course you want to move it to, either using the search tool or by entering the course’s ID.',
              )}
            </Text>
          </View>

          <View as="div" margin="0 0 medium 0">
            <CanvasAsyncSelect
              renderLabel={I18n.t('Search for Course')}
              inputValue={state.courseSearchValue}
              isLoading={state.isLoadingCourses}
              noOptionsLabel={I18n.t('No courses found')}
              onInputChange={(_e, value) => {
                dispatch({type: 'COURSE_SEARCH_CHANGED', payload: value})
                searchCourses(value)
              }}
              onOptionSelected={(_e, optionId) => {
                const course = state.courseOptions.find(c => c.id === optionId)
                if (course) confirmCourse(course.id, course.label)
              }}
              onBlur={() => {
                dispatch({type: 'SEARCH_FIELD_BLURRED'})
              }}
              isDisabled={state.isSubmitting}
              messages={getSearchMessages()}
              data-testid="course-search-input"
            >
              {state.courseOptions.map(course => (
                <CanvasAsyncSelect.Option key={course.id} id={course.id}>
                  <View as="div">
                    <Text>{course.label}</Text>
                  </View>
                  <View as="div">
                    <Text size="small" color="secondary">
                      {course.sis_id
                        ? I18n.t('SIS ID: %{sis_id} | Term: %{term}', {
                            sis_id: course.sis_id,
                            term: course.term,
                          })
                        : I18n.t('Term: %{term}', {term: course.term})}
                    </Text>
                  </View>
                </CanvasAsyncSelect.Option>
              ))}
            </CanvasAsyncSelect>
          </View>

          <View as="div" margin="0 0 medium 0">
            <TextInput
              renderLabel={I18n.t("Or Enter the Course's ID")}
              placeholder={I18n.t('Course ID')}
              value={state.courseIdValue}
              onChange={(_e, value) => {
                dispatch({type: 'COURSE_ID_CHANGED', payload: value})
                // Clear the last confirmed value when user changes the input
                lastConfirmedInputRef.current = null
              }}
              onBlur={() => {
                if (state.courseIdValue.trim()) {
                  confirmCourse(state.courseIdValue)
                }
              }}
              onKeyDown={e => {
                if (e.key === 'Enter' && state.courseIdValue.trim()) {
                  confirmCourse(state.courseIdValue)
                }
              }}
              messages={state.courseIdError ? [{type: 'newError', text: state.courseIdError}] : []}
              disabled={state.isSubmitting}
              data-testid="course-id-input"
            />
          </View>

          {(state.selectedCourse || state.isConfirming || state.submissionError) && (
            <View
              as="div"
              margin="medium 0 0 0"
              padding="small"
              background="secondary"
              data-testid="selected-course-display"
            >
              <View as="div" margin="0 0 small 0">
                <Text weight="bold">{I18n.t('Selected Course')}</Text>
              </View>
              <View as="div" margin="0 0 0 medium">
                {state.submissionError ? (
                  <Alert variant="error" margin="0">
                    {state.submissionError}
                  </Alert>
                ) : state.isConfirming ? (
                  <Text>
                    {I18n.t('Confirming %{course_name}...', {
                      course_name: state.selectedCourse?.name,
                    })}
                  </Text>
                ) : (
                  <>
                    <View as="div" margin="0 0 x-small 0" data-testid="selected-course-name">
                      <Text weight="bold">{state.selectedCourse!.name}</Text>
                    </View>
                    {state.selectedCourse!.sisId && (
                      <View as="div" margin="0 0 x-small 0">
                        <Text>
                          {I18n.t('SIS ID')}: {state.selectedCourse!.sisId}
                        </Text>
                      </View>
                    )}
                    {state.selectedCourse!.accountName && (
                      <View as="div">
                        <Text>
                          {I18n.t('Account')}: {state.selectedCourse!.accountName}
                        </Text>
                      </View>
                    )}
                  </>
                )}
              </View>
              {
                /* Hidden input used for integration tests only */
                ENV.RAILS_ENVIRONMENT !== 'production' && (
                  <input
                    type="hidden"
                    data-testid="confirmed-course-id"
                    value={state.confirmedCourseId || ''}
                  />
                )
              }
            </View>
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button
            onClick={handleClose}
            margin="0 x-small 0 0"
            disabled={state.isSubmitting}
            data-testid="crosslist-cancel-button"
          >
            {I18n.t('Cancel')}
          </Button>
          <Button
            color="primary"
            onClick={handleSubmit}
            disabled={state.isSubmitting || state.isConfirming}
            data-testid="crosslist-submit-button"
          >
            {state.isSubmitting
              ? I18n.t('Cross-Listing Section...')
              : I18n.t('Cross-List This Section')}
          </Button>
        </Modal.Footer>
      </Modal>
    </>
  )
}
