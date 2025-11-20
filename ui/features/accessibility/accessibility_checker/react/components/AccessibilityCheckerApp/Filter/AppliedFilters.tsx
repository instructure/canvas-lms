/**
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
import React from 'react'
import {Tag} from '@instructure/ui-tag'
import {AppliedFilter, FilterOption, Filters} from '../../../../../shared/react/types'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {getFilters} from '../../../utils/filter'
import * as tz from '@instructure/moment-utils/index'
import {useScope as createI18nScope} from '@canvas/i18n'
import {primitives} from '@instructure/ui-themes'

const I18n = createI18nScope('accessibility_checker')

interface AppliedFiltersProps {
  appliedFilters: AppliedFilter[]
  setFilters: (filters: Filters | null) => void
}

const formatDate = (date: Date | string) => {
  return tz.format(date, 'date.formats.medium')
}

const isDate = (val: unknown): val is Date => val instanceof Date

const getFilterLabel = (key: keyof Filters): string => {
  switch (key) {
    case 'ruleTypes':
      return I18n.t('With issues of')
    case 'artifactTypes':
      return I18n.t('Resource type')
    case 'workflowStates':
      return I18n.t('State')
    default:
      return ''
  }
}

const getDisplayValue = (key: keyof Filters, option: FilterOption): string => {
  if (isDate(option.value) || key === 'fromDate' || key === 'toDate') {
    return formatDate(option.value) ?? ''
  }

  return option.label ?? option.value?.toString() ?? ''
}

const AppliedFilters: React.FC<AppliedFiltersProps> = ({
  appliedFilters,
  setFilters,
}: AppliedFiltersProps) => {
  const handleDismiss = (key: string, option: FilterOption) => {
    const updated: AppliedFilter[] = appliedFilters.filter(
      f => !(f.key === key && f.option.value === option.value),
    )
    setFilters(getFilters(updated))
  }

  const handleDismissAllRuleTypes = () => {
    const updated: AppliedFilter[] = appliedFilters.filter(f => f.key !== 'ruleTypes')
    setFilters(getFilters(updated))
  }

  const handleDismissDateRange = () => {
    const updated: AppliedFilter[] = appliedFilters.filter(
      f => f.key !== 'fromDate' && f.key !== 'toDate',
    )
    setFilters(getFilters(updated))
  }

  const ruleTypeFilters = appliedFilters.filter(f => f.key === 'ruleTypes')
  const fromDateFilter = appliedFilters.find(f => f.key === 'fromDate')
  const toDateFilter = appliedFilters.find(f => f.key === 'toDate')
  const otherFilters = appliedFilters.filter(
    f => f.key !== 'ruleTypes' && f.key !== 'fromDate' && f.key !== 'toDate',
  )

  const displayFilters: Array<{
    filter: AppliedFilter
    isCondensed: boolean
    additionalCount?: number
    customLabel?: string
    customValue?: string
    customDismiss?: () => void
  }> = []

  if (ruleTypeFilters.length > 1) {
    displayFilters.push({
      filter: ruleTypeFilters[0],
      isCondensed: true,
      additionalCount: ruleTypeFilters.length - 1,
    })
  } else if (ruleTypeFilters.length === 1) {
    displayFilters.push({
      filter: ruleTypeFilters[0],
      isCondensed: false,
    })
  }

  if (fromDateFilter || toDateFilter) {
    const fromValue = fromDateFilter ? getDisplayValue('fromDate', fromDateFilter.option) : null
    const toValue = toDateFilter ? getDisplayValue('toDate', toDateFilter.option) : null

    const dateRangeValue =
      fromValue && toValue
        ? `${fromValue} - ${toValue}`
        : fromValue
          ? `${fromValue} - ${I18n.t('Today')}`
          : `${I18n.t('up to')} ${toValue}`

    displayFilters.push({
      filter: fromDateFilter || toDateFilter!,
      isCondensed: false,
      customLabel: I18n.t('Last edited'),
      customValue: dateRangeValue,
      customDismiss: handleDismissDateRange,
    })
  }

  otherFilters.forEach(filter => {
    displayFilters.push({
      filter,
      isCondensed: false,
    })
  })

  return (
    <View as="div" width="100%" data-testid="applied-filters">
      {displayFilters.map((item, index: number) => {
        const prefix = item.customLabel || getFilterLabel(item.filter.key)
        const value = item.customValue || getDisplayValue(item.filter.key, item.filter.option)
        const displayValue = item.isCondensed ? `${value} +${item.additionalCount}` : value
        const handleClick = item.customDismiss
          ? item.customDismiss
          : item.isCondensed
            ? handleDismissAllRuleTypes
            : () => handleDismiss(item.filter.key, item.filter.option)
        return (
          <Tag
            key={index}
            margin="x-small"
            dismissible
            onClick={handleClick}
            text={
              <span style={{whiteSpace: 'nowrap'}}>
                <Text weight="weightImportant" color="secondary" size="contentSmall">
                  {prefix}:
                </Text>{' '}
                <Text weight="normal" color="secondary" size="contentSmall">
                  {displayValue}
                </Text>
              </span>
            }
            themeOverride={{
              maxWidth: 'none',
              defaultBackground: 'white',
              defaultBorderColor: primitives.grey30,
            }}
          />
        )
      })}
    </View>
  )
}

export default AppliedFilters
