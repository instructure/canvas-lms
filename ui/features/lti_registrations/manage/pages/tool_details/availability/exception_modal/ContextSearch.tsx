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
import {queryify} from '@canvas/query/queryify'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {
  IconCoursesLine,
  IconSearchLine,
  IconSubaccountsLine,
  IconTroubleLine,
} from '@instructure/ui-icons'
import {Select} from '@instructure/ui-select'
import {View} from '@instructure/ui-view'
import {useQuery} from '@tanstack/react-query'
import * as React from 'react'
import {useDebouncedCallback} from 'use-debounce'
import {isSuccessful} from '../../../../../common/lib/apiResult/ApiResult'
import {fetchContextSearch} from '../../../../api/contexts'
import {AccountId} from '../../../../model/AccountId'
import {CourseId} from '../../../../model/CourseId'
import {ContextOption} from './ContextOption'
import {ContextSearchOption} from './ContextSearchOption'

const I18n = createI18nScope('lti_registrations')

type OptionId = `account-${AccountId}` | `course-${CourseId}`
const mkAccountOptionId = (accountId: AccountId): OptionId => `account-${accountId}`
const mkCourseOptionId = (courseId: CourseId): OptionId => `course-${courseId}`

type ContextSearchProps = {
  accountId: AccountId
  disabled: boolean
  onSelectContext?: (context: ContextSearchOption) => void
}

export const ContextSearch = (props: ContextSearchProps) => {
  const [searchText, setSearchText] = React.useState('')

  const [state, setState] = React.useState<{
    inputValue: string
    isShowingOptions: boolean
    highlightedOptionId: undefined | OptionId
    selectedOptionId: undefined | string
  }>({
    inputValue: '',
    isShowingOptions: false,
    highlightedOptionId: undefined,
    selectedOptionId: undefined,
  })

  const setSearchTextDebounced = useDebouncedCallback(setSearchText, 1000)

  const searchContextsQuery = useQuery({
    queryKey: ['searchableContexts', props.accountId, searchText],
    queryFn: queryify(fetchContextSearch),
  })

  const contexts =
    searchContextsQuery.data && isSuccessful(searchContextsQuery.data)
      ? searchContextsQuery.data.data
      : {
          accounts: [],
          courses: [],
        }

  const handleClearInput = React.useCallback(() => {
    setSearchText('')
    setState(state => ({
      ...state,
      isShowingOptions: false,
      highlightedOptionId: undefined,
      selectedOptionId: undefined,
      inputValue: '',
    }))
  }, [])

  const accounts = contexts.accounts
  const courses = contexts.courses

  const getOptionById = React.useCallback(
    (id: OptionId) => {
      if (id.startsWith('account-')) {
        const accountId = id.replace('account-', '') as AccountId
        const account = contexts.accounts.find(account => account.id === accountId)
        if (!account) {
          console.warn(`Account with id ${accountId} not found in options`)
          return undefined
        } else {
          return {
            type: 'account',
            id,
            context: account,
            name: account?.name || '',
          } as const
        }
      } else {
        const courseId = id.replace('course-', '') as CourseId
        const course = contexts.courses.find(course => course.id === courseId)
        if (!course) {
          console.warn(`Course with id ${courseId} not found in options`)
          return undefined
        } else {
          return {
            type: 'course',
            id,
            context: course,
            name: contexts.courses.find(course => course.id === courseId)?.name || '',
          } as const
        }
      }
    },
    [contexts.accounts, contexts.courses],
  )

  const renderAfterInput = React.useMemo(() => {
    if (searchText.length <= 0) {
      return null
    }

    return (
      <IconButton
        type="button"
        size="small"
        withBackground={false}
        withBorder={false}
        screenReaderLabel="Clear search"
        onClick={handleClearInput}
      >
        <IconTroubleLine />
      </IconButton>
    )
  }, [searchText, handleClearInput])

  const handleHideOptions = React.useCallback((_event: React.SyntheticEvent) => {
    setState(state => ({
      ...state,
      isShowingOptions: false,
      highlightedOptionId: undefined,
    }))
  }, [])

  const handleBlur = React.useCallback((_event: React.FocusEvent<HTMLInputElement>) => {
    setState(state => ({...state, highlightedOptionId: undefined}))
  }, [])

  const handleHighlightOption = React.useCallback(
    (
      _event: React.SyntheticEvent,
      data: {
        id?: string
        direction?: 1 | -1
      },
    ) => {
      const option = 'id' in data && data.id ? getOptionById(data.id as OptionId) : undefined
      if (!option) return // prevent highlighting of empty option
      setState(state => ({
        ...state,
        highlightedOptionId: data.id as OptionId,
      }))
    },
    [getOptionById],
  )

  const handleSelectOption = React.useCallback(
    (
      _event: React.SyntheticEvent,
      data: {
        id?: string
      },
    ) => {
      const option = 'id' in data && data.id ? getOptionById(data.id as OptionId) : undefined
      if (!option) return // prevent selecting of empty option
      setState(state => ({
        ...state,
        selectedOptionId: data.id,
        inputValue: '',
        showingOptions: false,
        isShowingOptions: false,
      }))
      if (props.onSelectContext) {
        props.onSelectContext(
          option.type === 'course'
            ? ({
                type: 'course',
                context: option.context,
              } as const)
            : ({
                type: 'account',
                context: option.context,
              } as const),
        )
      }
    },
    [getOptionById, props.onSelectContext],
  )

  const handleInputChange = React.useCallback(
    (event: React.ChangeEvent<HTMLInputElement>) => {
      const value = event.target.value
      setSearchTextDebounced(value)
      setState(state => ({
        ...state,
        inputValue: value,
        isShowingOptions: true,
      }))
    },
    [setSearchTextDebounced],
  )

  return (
    <View as="div">
      <Select
        disabled={props.disabled}
        renderLabel={''}
        assistiveText={I18n.t('Type or use arrow keys to navigate options.')}
        placeholder={I18n.t('Search by sub-accounts or courses')}
        inputValue={state.inputValue}
        isShowingOptions={state.isShowingOptions}
        onBlur={handleBlur}
        onInputChange={handleInputChange}
        onRequestShowOptions={React.useMemo(
          () => () =>
            setState(state => ({
              ...state,
              isShowingOptions: true,
            })),
          [],
        )}
        onRequestHideOptions={handleHideOptions}
        onRequestHighlightOption={handleHighlightOption}
        onRequestSelectOption={handleSelectOption}
        renderBeforeInput={<IconSearchLine inline={false} />}
        renderAfterInput={renderAfterInput}
        shouldNotWrap
      >
        {accounts.length > 0 ? (
          <Select.Group
            renderLabel={
              <Flex alignItems="center">
                <Flex.Item margin="0 x-small 0 0">
                  <IconSubaccountsLine />
                </Flex.Item>
                <Flex.Item>{I18n.t('Sub-accounts')}</Flex.Item>
              </Flex>
            }
          >
            {accounts.map(option => {
              const optionId = mkAccountOptionId(option.id)
              return (
                <Select.Option
                  id={optionId}
                  key={optionId}
                  isHighlighted={optionId === state.highlightedOptionId}
                  isSelected={optionId === state.selectedOptionId}
                >
                  <ContextOption context={option} margin="0 x-small 0 medium" />
                </Select.Option>
              )
            })}
          </Select.Group>
        ) : undefined}

        {courses.length > 0 ? (
          <Select.Group
            renderLabel={
              <Flex alignItems="center">
                <Flex.Item margin="0 x-small 0 0">
                  <IconCoursesLine />
                </Flex.Item>
                <Flex.Item>{I18n.t('Courses')}</Flex.Item>
              </Flex>
            }
          >
            {courses.map(course => {
              const optionId = mkCourseOptionId(course.id)

              return (
                <Select.Option
                  id={optionId}
                  key={optionId}
                  isHighlighted={optionId === state.highlightedOptionId}
                  isSelected={optionId === state.selectedOptionId}
                >
                  <ContextOption context={course} margin="0 x-small 0 medium" />
                </Select.Option>
              )
            })}
          </Select.Group>
        ) : null}

        {contexts.courses.length === 0 &&
        contexts.accounts.length === 0 &&
        !searchContextsQuery.isLoading ? (
          <Select.Option id="empty-option" disabled>
            {I18n.t('No results found')}
          </Select.Option>
        ) : undefined}

        {searchContextsQuery.isLoading ? (
          <Select.Option id="loading-option" disabled>
            {I18n.t('Loading...')}
          </Select.Option>
        ) : undefined}
      </Select>
    </View>
  )
}
