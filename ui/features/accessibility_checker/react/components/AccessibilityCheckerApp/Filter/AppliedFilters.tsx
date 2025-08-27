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
import {AppliedFilter, FilterOption, Filters} from '../../../types'
import {View} from '@instructure/ui-view'
import {getFilters} from '../../../utils/filter'
import * as tz from '@instructure/moment-utils'

interface AppliedFiltersProps {
  appliedFilters: AppliedFilter[]
  setFilters: (filters: Filters | null) => void
}

const formatDate = (date: Date) => {
  return tz.format(date, 'date.formats.medium')
}

const isDate = (val: unknown): val is Date => val instanceof Date

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

  return (
    <View as="div" width="100%" data-testid="applied-filters">
      {appliedFilters.map((filter: AppliedFilter, index: number) => (
        <Tag
          text={
            isDate(filter.option.value)
              ? formatDate(filter.option.value)
              : (filter.option.label ?? '')
          }
          key={index}
          margin="x-small"
          dismissible
          onClick={() => handleDismiss(filter.key, filter.option)}
        />
      ))}
    </View>
  )
}

export default AppliedFilters
