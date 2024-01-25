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
import React, {type ReactElement, useEffect, useRef, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Link} from '@instructure/ui-link'
import {View} from '@instructure/ui-view'
import {debounce} from 'lodash'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {setContainScrollBehavior} from '../utils/assignToHelper'
import useFetchAssignees from '../utils/hooks/useFetchAssignees'
import type {FormMessage} from '@instructure/ui-form-field'

const {Option: CanvasMultiSelectOption} = CanvasMultiSelect as any

const I18n = useI18nScope('differentiated_modules')

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
}

export interface AssigneeOption {
  id: string
  value: string
  overrideId?: string
  group?: string
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
}: Props) => {
  const listElementRef = useRef<HTMLElement | null>(null)
  const [options, setOptions] = useState<AssigneeOption[]>(defaultValues)
  const [isShowingOptions, setIsShowingOptions] = useState(false)
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

  const shouldUpdateOptions = [
    JSON.stringify(allOptions),
    JSON.stringify(disabledOptionIds),
    JSON.stringify(selectedOptionIds),
  ]

  useEffect(() => {
    const newOptions = allOptions.filter(
      option => selectedOptionIds.includes(option.id) || !disabledOptionIds.includes(option.id)
    )
    setOptions(newOptions)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, shouldUpdateOptions)

  const handleSelectOption = () => {
    setIsShowingOptions(false)
  }

  const handleChange = (newSelected: string[]) => {
    const newSelectedSet = new Set(newSelected)
    const selected = options.filter(option => newSelectedSet.has(option.id))
    onSelect(selected)
  }

  const handleInputChange = debounce(value => setSearchTerm(value), 500)

  const handleShowOptions = () => {
    setIsShowingOptions(true)
    setTimeout(() => {
      setContainScrollBehavior(listElementRef.current)
    }, 500)
  }

  const label = I18n.t('Assign To')

  return (
    <>
      <CanvasMultiSelect
        data-testid="assignee_selector"
        messages={messages}
        label={showVisualLabel ? label : <ScreenReaderContent>{label}</ScreenReaderContent>}
        size={size}
        selectedOptionIds={selectedOptionIds}
        onChange={handleChange}
        renderAfterInput={<></>}
        customOnInputChange={handleInputChange}
        visibleOptionsCount={10}
        isLoading={isLoading}
        listRef={e => (listElementRef.current = e)}
        isShowingOptions={isShowingOptions}
        customOnRequestShowOptions={handleShowOptions}
        customOnRequestHideOptions={() => setIsShowingOptions(false)}
        customOnRequestSelectOption={handleSelectOption}
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
      >
        {options.map(option => {
          return (
            <CanvasMultiSelectOption
              id={option.id}
              value={option.id}
              key={option.id}
              group={option.group}
            >
              {option.value}
            </CanvasMultiSelectOption>
          )
        })}
      </CanvasMultiSelect>
      {!clearAllDisabled && (
        <View as="div" textAlign="end" margin="small none">
          <Link
            data-testid="clear_selection_button"
            onClick={() => onSelect([])}
            isWithinText={false}
          >
            <span aria-hidden={true}>{I18n.t('Clear All')}</span>
            <ScreenReaderContent>{I18n.t('Clear Assign To')}</ScreenReaderContent>
          </Link>
        </View>
      )}
    </>
  )
}

export default AssigneeSelector
