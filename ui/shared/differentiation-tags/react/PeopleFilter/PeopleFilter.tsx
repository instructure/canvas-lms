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

import React, {useState, useRef, useEffect} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useDifferentiationTagCategoriesIndex} from '../hooks/useDifferentiationTagCategoriesIndex'
import MessageBus from '@canvas/util/MessageBus'
import {QueryClientProvider} from '@tanstack/react-query'
import {queryClient} from '@canvas/query'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {
  AllRolesOption,
  RoleOption,
  DifferentiationTagCategory,
  DifferentiationTagGroup,
} from '../types'
import {Select} from '@instructure/ui-select'
import {Tag} from '@instructure/ui-tag'

const I18n = createI18nScope('differentiation_tags')

const ALL_ROLES_OPTION: AllRolesOption = {id: '0', name: I18n.t('All Roles')}

const ROLE_FILTER_KEY = 'enrollment_role_id'
const TAG_FILTER_KEY = 'differentiation_tag_id'
export interface PeopleFilterProps {
  courseId: number
}
function PeopleFilter(props: PeopleFilterProps) {
  const {courseId} = props
  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [highlightedOptionId, setHighlightedOptionId] = useState<string | null>(null)
  const [selectedOptionId, setSelectedOptionId] = useState<string[]>([
    `${ROLE_FILTER_KEY}#${ALL_ROLES_OPTION.id}`,
  ])
  const inputRef = useRef<HTMLInputElement | null>(null)

  // Ensure 'All Roles' is always selected if no roles are present
  useEffect(() => {
    if (selectedOptionId.length > 0) {
      const result = selectedOptionId.reduce(
        (acc: Record<string, number[]>, item) => {
          const [key, value] = item.split('#')
          if (!acc[key]) acc[key] = []
          acc[key].push(parseInt(value))
          return acc
        },
        {} as Record<string, number[]>,
      )
      // Remove enrollment_role_id: [0] if present
      if (
        result.enrollment_role_id &&
        result.enrollment_role_id.length === 1 &&
        result.enrollment_role_id[0] === 0
      ) {
        delete result.enrollment_role_id
      }
      MessageBus.trigger('peopleFilterChange', result)
    }
  }, [selectedOptionId])

  const {
    data: differentiationTagCategories,
    isLoading,
    error,
  } = useDifferentiationTagCategoriesIndex(courseId, {
    includeDifferentiationTags: true,
    enabled: true,
  }) as {data: DifferentiationTagCategory[]; isLoading: boolean; error: any}
  const focusInput = () => {
    if (inputRef.current) {
      inputRef.current?.blur()
      inputRef.current?.focus()
    }
  }

  const getOptionById = (
    id: string,
  ): AllRolesOption | RoleOption | DifferentiationTagGroup | undefined => {
    const params = id.split('#')
    if (params[1] === ALL_ROLES_OPTION.id) {
      return ALL_ROLES_OPTION
    } else if (params[0].includes(ROLE_FILTER_KEY)) {
      return ((window as any).ENV.ALL_ROLES as RoleOption[]).find(
        (role: RoleOption) => role.id === params[1],
      )
    } else if (params[0].includes(TAG_FILTER_KEY)) {
      return differentiationTagCategories
        ?.flatMap((category: DifferentiationTagCategory) => category.groups || [])
        .find((group: DifferentiationTagGroup) => group.id === parseInt(params[1]))
    }
  }

  const handleShowOptions = (
    event: React.KeyboardEvent | React.SyntheticEvent,
    data?: {id?: string; direction?: 1 | -1},
  ) => {
    setIsShowingOptions(true)
    setHighlightedOptionId(null)
    if (selectedOptionId) return
    if (
      'key' in event &&
      (event as React.KeyboardEvent).key &&
      ['ArrowDown', 'ArrowUp'].includes((event as React.KeyboardEvent).key)
    )
      handleHighlightOption(event, {id: selectedOptionId})
  }

  const handleHideOptions = (event: React.SyntheticEvent, data?: {id?: string}) => {
    setIsShowingOptions(false)
    setHighlightedOptionId(null)
  }

  const handleBlur = (event: React.FocusEvent) => {
    setHighlightedOptionId(null)
  }

  const handleHighlightOption = (
    event: React.SyntheticEvent,
    data: {id?: string; direction?: 1 | -1},
  ) => {
    const id = data.id ?? ''
    if (typeof event === 'object' && typeof (event as any).persist === 'function') {
      ;(event as any).persist()
    }
    setHighlightedOptionId(id)
  }
  const renderTags = () => {
    return selectedOptionId.map((id: string, index: number) => {
      const option = getOptionById(id)
      if (!option) return null
      return (
        <Tag
          dismissible
          key={id}
          text={
            <AccessibleContent
              alt={I18n.t('Remove Filter %{name}', {name: (option as any).label ?? option.name})}
            >
              {(option as any).label ?? option.name}
            </AccessibleContent>
          }
          margin={index > 0 ? 'xxx-small xx-small xxx-small 0' : '0 xx-small 0 0'}
          onClick={e => dismissTag(e as unknown as React.MouseEvent<HTMLElement>, id)}
        />
      )
    })
  }

  interface DismissTagEvent extends React.MouseEvent<HTMLElement> {}

  interface DismissTag {
    (e: DismissTagEvent, tag: string): void
  }

  const dismissTag: DismissTag = (e, tag) => {
    // prevent closing of list
    e.stopPropagation()
    e.preventDefault()

    let newSelection = selectedOptionId.filter(id => id !== tag)
    // If no role is selected, re-add 'All Roles'
    const hasRole = newSelection.some(id => id.startsWith(ROLE_FILTER_KEY))
    if (!hasRole) {
      newSelection = [`${ROLE_FILTER_KEY}#${ALL_ROLES_OPTION.id}`, ...newSelection]
    }
    setSelectedOptionId(newSelection)
    setHighlightedOptionId(null)
    inputRef.current?.focus()
  }

  const handleSelectOption = (event: React.SyntheticEvent, data: {id?: string}) => {
    const id = data.id ?? ''
    const param = id.split('#')
    focusInput()
    const isRole = id.startsWith(ROLE_FILTER_KEY)
    let newSelection = [...selectedOptionId]
    if (isRole) {
      if (id === `${ROLE_FILTER_KEY}#${ALL_ROLES_OPTION.id}`) {
        newSelection = newSelection.filter(sel => !sel.startsWith(ROLE_FILTER_KEY))
      } else {
        newSelection = newSelection.filter(
          sel => sel !== `${ROLE_FILTER_KEY}#${ALL_ROLES_OPTION.id}`,
        )
      }
    }
    if (!newSelection.includes(id)) {
      newSelection = [...newSelection, id]
    }

    setSelectedOptionId(newSelection)
    setIsShowingOptions(false)
  }
  return (
    <Select
      id="people-filter-select"
      isInline
      renderLabel=""
      assistiveText={I18n.t('Filter People by Role or Tag. Use key down arrow to select options')}
      inputValue=""
      isShowingOptions={isShowingOptions}
      onBlur={handleBlur}
      onRequestShowOptions={handleShowOptions}
      onRequestHideOptions={handleHideOptions}
      onRequestHighlightOption={handleHighlightOption}
      onRequestSelectOption={handleSelectOption}
      inputRef={(el: HTMLInputElement | null) => {
        inputRef.current = el
      }}
      renderBeforeInput={renderTags()}
    >
      <Select.Group key={I18n.t('Roles')} renderLabel={I18n.t('Roles')}>
        {[
          ALL_ROLES_OPTION,
          ...(((window as any).ENV.ALL_ROLES as Array<{
            id: string
            name: string
            count: number
          }>) || []),
        ]
          .filter(
            (opt: AllRolesOption | RoleOption) =>
              !selectedOptionId.includes(`${ROLE_FILTER_KEY}#${opt.id}`),
          )
          .map((option: AllRolesOption | RoleOption) => (
            <Select.Option
              key={option.id}
              data-testid={`${ROLE_FILTER_KEY}#${option.id}`}
              id={`${ROLE_FILTER_KEY}#${option.id}`}
              isHighlighted={`${ROLE_FILTER_KEY}#${option.id}` === highlightedOptionId}
              aria-label={I18n.t(
                {
                  one: 'Filter by Role: %{name} - %{count} user.',
                  other: 'Filter by Role: %{name} - %{count} users.',
                },
                {
                  name: (option as any).label ?? option.name,
                  count: (option as RoleOption).count,
                },
              )}
            >
              {option.id === '0'
                ? ((option as any).label ?? option.name)
                : `${(option as any).label ?? option.name}${'count' in option ? ` (${(option as RoleOption).count})` : ''}`}
            </Select.Option>
          ))}
      </Select.Group>
      {differentiationTagCategories && differentiationTagCategories.length > 0 && (
        <Select.Group key={I18n.t('Tags')} renderLabel={I18n.t('Tags')}>
          {differentiationTagCategories.flatMap(option =>
            (option.groups ?? [])
              .filter(
                (opt: DifferentiationTagGroup) =>
                  !selectedOptionId.includes(`${TAG_FILTER_KEY}#${opt.id}`),
              )
              .map((opt: DifferentiationTagGroup) => (
                <Select.Option
                  key={opt.id}
                  data-testid={`${TAG_FILTER_KEY}#${opt.id}`}
                  id={`${TAG_FILTER_KEY}#${opt.id}`}
                  isHighlighted={`${TAG_FILTER_KEY}#${opt.id}` === highlightedOptionId}
                  aria-label={I18n.t(
                    {
                      one: 'Filter by Tag: %{name} - %{count} student.',
                      other: 'Filter by Tag: %{name} - %{count} students.',
                    },
                    {name: opt.name, count: opt.members_count},
                  )}
                >
                  {`${opt.name} (${opt.members_count})`}
                </Select.Option>
              )),
          )}
        </Select.Group>
      )}
    </Select>
  )
}

export default function PeopleFilterContainer(props: PeopleFilterProps) {
  return (
    <QueryClientProvider client={queryClient}>
      <PeopleFilter {...props} />
    </QueryClientProvider>
  )
}
