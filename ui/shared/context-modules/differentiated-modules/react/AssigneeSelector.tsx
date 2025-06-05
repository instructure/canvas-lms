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

import CanvasMultiSelect, {type Size} from '@canvas/multi-select/react'
import React, {type ReactElement, useEffect, useRef, useState, useCallback, useMemo} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Link} from '@instructure/ui-link'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {debounce} from 'lodash'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {setContainScrollBehavior} from '../utils/assignToHelper'
import useFetchAssignees from '../utils/hooks/useFetchAssignees'
import type {FormMessage} from '@instructure/ui-form-field'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import type {AssigneeOption} from './Item/types'
import type {ItemType} from './types'
import AlertManager from '@canvas/alerts/react/AlertManager'

const {Option: CanvasMultiSelectOption} = CanvasMultiSelect as any

const I18n = createI18nScope('differentiated_modules')

interface Props {
  courseId: string
  onSelect: (options: AssigneeOption[]) => void
  defaultValues: AssigneeOption[]
  selectedOptionIds: string[]
  clearAllDisabled?: boolean
  size?: Size
  messages?: FormMessage[]
  disabledOptionIds?: string[]
  everyoneOption?: AssigneeOption
  disableFetch?: boolean // avoid mutating the state when closing the tray
  customAllOptions?: AssigneeOption[]
  customIsLoading?: boolean
  customSetSearchTerm?: (term: string) => void
  onError?: () => void
  showVisualLabel?: boolean
  inputRef?: (inputElement: HTMLInputElement | null) => void
  onBlur?: () => void
  disabledWithGradingPeriod?: boolean
  disabledOptionIdsRef?: React.MutableRefObject<string[]>
  itemType?: ItemType
}

const AssigneeSelector = ({
  courseId,
  onSelect,
  defaultValues,
  selectedOptionIds = [],
  clearAllDisabled,
  size = 'large',
  messages,
  disabledOptionIds = [],
  disableFetch = false,
  everyoneOption,
  customAllOptions,
  customIsLoading,
  customSetSearchTerm,
  onError,
  showVisualLabel = true,
  inputRef,
  onBlur,
  disabledWithGradingPeriod,
  disabledOptionIdsRef,
  itemType,
}: Props) => {
  const listElementRef = useRef<HTMLElement | null>(null)
  const [options, setOptions] = useState<AssigneeOption[]>(defaultValues)
  const [loadedOptions, setloadedOptions] = useState<AssigneeOption[]>([])
  const [searchLoading, setSearchLoading] = useState(false)
  const {allOptions, isLoading, setSearchTerm} = useFetchAssignees({
    courseId,
    everyoneOption,
    defaultValues,
    disableFetch,
    customAllOptions,
    customIsLoading,
    customSetSearchTerm,
    onError,
  })
  const [highlightedOptionId, setHighlightedOptionId] = useState<string | null>(null)
  const disabledOptions = disabledOptionIdsRef?.current ?? disabledOptionIds

  const shouldUpdateOptions = [
    JSON.stringify(allOptions),
    JSON.stringify(loadedOptions),
    JSON.stringify(disabledOptions),
    JSON.stringify(selectedOptionIds),
  ]

  const filteredOptions = useCallback(() => {
    const unfilteredOptions =
      isLoading && loadedOptions.length > 0
        ? loadedOptions
        : [...new Map([...allOptions, ...defaultValues].map(item => [item.id, item])).values()]
    return unfilteredOptions.filter(
      option => selectedOptionIds.includes(option.id) || !disabledOptions.includes(option.id),
    )
  }, [allOptions, defaultValues, disabledOptions, isLoading, loadedOptions, selectedOptionIds])

  useEffect(() => {
    setOptions(filteredOptions())
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, shouldUpdateOptions)

  const handleChange = (newSelected: string[]) => {
    const newSelectedSet = new Set(newSelected)
    const selected = options.filter(option => newSelectedSet.has(option.id))
    onSelect(selected)
  }

  const handleInputChange = debounce(value => {
    setSearchTerm(value)

    if (value.length >= 2 && isLoading) {
      setSearchLoading(true)
      doFetchApi({
        path: `/api/v1/courses/${courseId}/users?search_term=${value}&enrollment_type=student&per_page=100`,
        method: 'GET',
      })
        .then(({json}) => {
          if ((json as any[]).length === 0) {
            setSearchLoading(false)
            return
          }
          const combinedLoadedOptions = [
            ...(loadedOptions.length === 0 ? allOptions : []),
            ...loadedOptions,
            ...defaultValues,
            ...(json as any[]).map((user: any) => ({
              id: `student-${user.id}`,
              value: user.name,
              sisID: user.sis_user_id,
              group: 'Students',
            })),
          ]
          setloadedOptions([
            ...new Map([...combinedLoadedOptions].map(item => [item.id, item])).values(),
          ])
        })
        .catch((err: Error) => {
          showFlashAlert({
            err,
            message: I18n.t(`An error occurred while searching`),
          })
        })
    }
  }, 500)

  const handleShowOptions = () => {
    setTimeout(() => {
      setContainScrollBehavior(listElementRef.current)
    }, 500)
  }

  const handleClear = () => {
    onSelect([])
    showFlashAlert({message: I18n.t('All assignees removed'), srOnly: true})
  }

  const label = I18n.t('Assign To')

  const optionMatcher = (
    option: {
      id: string
    },
    term: string,
  ): boolean => {
    const unfilteredOptions = isLoading && loadedOptions.length > 0 ? loadedOptions : allOptions
    const selectedOption = unfilteredOptions.find(o => o.id === option.id)
    return (
      selectedOption?.value.toLowerCase().includes(term.toLowerCase()) ||
      selectedOption?.sisID?.toLowerCase().includes(term.toLowerCase()) ||
      false
    )
  }

  const handleFocus = useCallback(() => {
    setOptions(filteredOptions())
  }, [filteredOptions])

  const handleClick = useCallback(() => {
    setSearchLoading(false)
  }, [])

  const shouldDisableSelector = useMemo(() => {
    if (!(itemType === 'discussion' || itemType === 'discussion_topic')) return false
    return ENV?.current_user_is_student
  }, [itemType])

  return (
    <AlertManager breakpoints={{}}>
      <CanvasMultiSelect
        disabled={disabledWithGradingPeriod || shouldDisableSelector}
        data-testid="assignee_selector"
        messages={messages}
        label={showVisualLabel ? label : <ScreenReaderContent>{label}</ScreenReaderContent>}
        size={size}
        selectedOptionIds={selectedOptionIds}
        onChange={handleChange}
        placeholder={I18n.t('Start typing to search...')}
        customOnInputChange={handleInputChange}
        visibleOptionsCount={10}
        isLoading={isLoading && searchLoading}
        isRequired={true}
        setInputRef={inputRef}
        listRef={e => (listElementRef.current = e)}
        customOnRequestShowOptions={handleShowOptions}
        // @ts-expect-error
        onFocus={handleFocus}
        onClick={handleClick}
        customRenderBeforeInput={tags =>
          tags?.map((tag: ReactElement) => (
            <View
              key={tag.key}
              data-testid="assignee_selector_selected_option"
              as="div"
              display="inline-block"
              margin="xx-small none"
            >
              {tag}
            </View>
          ))
        }
        customMatcher={optionMatcher}
        onUpdateHighlightedOption={setHighlightedOptionId}
        customOnBlur={onBlur}
      >
        {(!isLoading || searchLoading
          ? options
          : options.filter(
              option => option.group !== 'Students' || selectedOptionIds.includes(option.id),
            )
        ).map(option => {
          return (
            <CanvasMultiSelectOption
              id={option.id}
              value={option.id}
              key={option.id}
              group={option.group}
              tagText={option.value}
              data-testid={'assignee_selector_option'}
            >
              <Text as="div">{option.value}</Text>
              {option.sisID && (
                <Text
                  as="div"
                  size="small"
                  color={highlightedOptionId === option.id ? 'secondary-inverse' : 'secondary'}
                >
                  {option.sisID}
                </Text>
              )}
              {option.groupCategoryName && (
                <Text
                  as="div"
                  size="small"
                  color={highlightedOptionId === option.id ? 'secondary-inverse' : 'secondary'}
                >
                  {option.groupCategoryName}
                </Text>
              )}
            </CanvasMultiSelectOption>
          )
        })}
      </CanvasMultiSelect>
      {!clearAllDisabled && (
        <View as="div" textAlign="end" margin="small none">
          <Link data-testid="clear_selection_button" onClick={handleClear} isWithinText={false}>
            <span aria-hidden={true}>{I18n.t('Clear All')}</span>
            <ScreenReaderContent>{I18n.t('Clear Assign To')}</ScreenReaderContent>
          </Link>
        </View>
      )}
    </AlertManager>
  )
}

export default AssigneeSelector
