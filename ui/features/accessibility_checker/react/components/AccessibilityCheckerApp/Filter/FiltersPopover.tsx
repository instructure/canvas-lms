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

import React, {useState, useEffect} from 'react'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {CloseButton, Button} from '@instructure/ui-buttons'
import {Badge} from '@instructure/ui-badge'
import CanvasDateInput2 from '@canvas/datetime/react/components/DateInput2'
import {Flex} from '@instructure/ui-flex'
import {IconFilterLine} from '@instructure/ui-icons'
import FilterDropDown from './FilterDropDown'
import {Popover} from '@instructure/ui-popover'
import {useScope as createI18nScope} from '@canvas/i18n'
import {artifactTypeOptions, issueTypeOptions, stateOptions} from '../../../constants'
import {AppliedFilter, FilterOption, Filters} from '../../../types'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'
import {getFilters} from '../../../utils/filter'

const I18n = createI18nScope('accessibility_checker')

interface FiltersPopoverProps {
  onFilterChange: (filters: null | Filters) => void
  appliedFilters?: AppliedFilter[]
}

const FiltersPopover: React.FC<FiltersPopoverProps> = ({
  onFilterChange,
  appliedFilters = [],
}: FiltersPopoverProps) => {
  const [isOpen, setIsOpen] = useState(false)
  const [selectedIssues, setSelectedIssues] = useState<FilterOption[]>([
    {label: 'all', value: 'all'},
  ])
  const [selectedArtifactType, setSelectedArtifactType] = useState<FilterOption[]>([
    {label: 'all', value: 'all'},
  ])
  const [selectedState, setSelectedState] = useState<FilterOption[]>([{label: 'all', value: 'all'}])
  const [fromDate, setFromDate] = useState<FilterOption | null>(null)
  const [toDate, setToDate] = useState<FilterOption | null>(null)
  const [filterCount, setFilterCount] = useState(0)

  const dateFormatter = useDateTimeFormat('date.formats.medium_with_weekday')

  useEffect(() => {
    const filters = getFilters(appliedFilters)
    setSelectedIssues(filters.ruleTypes || [{label: 'all', value: 'all'}])
    setSelectedArtifactType(filters.artifactTypes || [{label: 'all', value: 'all'}])
    setSelectedState(filters.workflowStates || [{label: 'all', value: 'all'}])
    setFromDate(filters.fromDate || null)
    setToDate(filters.toDate || null)
    setFilterCount(appliedFilters.length)
  }, [appliedFilters])

  const getFilterSelections = (): Filters => {
    return {
      ruleTypes: selectedIssues,
      artifactTypes: selectedArtifactType,
      workflowStates: selectedState,
      fromDate: fromDate || null,
      toDate: toDate || null,
    }
  }

  const handleReset = () => {
    setSelectedIssues([{label: 'all', value: 'all'}])
    setSelectedArtifactType([{label: 'all', value: 'all'}])
    setSelectedState([{label: 'all', value: 'all'}])
    setFromDate(null)
    setToDate(null)
    setFilterCount(0)
    onFilterChange(null)
    setIsOpen(false)
  }

  const handleClose = () => {
    const filters = getFilterSelections()
    setFilterCount(appliedFilters.length)
    onFilterChange(filters)
    setIsOpen(false)
  }

  const handleDateChange = (
    date: Date | null,
    setDate: (date: FilterOption | null) => void,
    label: string,
  ) => {
    if (date) {
      setDate({label: `${label}: ${dateFormatter(date)}`, value: date.toISOString()})
    } else {
      setDate(null)
    }
  }

  return (
    <Popover
      isShowingContent={isOpen}
      onShowContent={() => setIsOpen(true)}
      onHideContent={handleClose}
      on="click"
      placement="bottom end"
      shouldContainFocus
      shouldReturnFocus
      mountNode={() => document.body}
      renderTrigger={(triggerProps: Record<string, any>) => (
        <Badge count={filterCount}>
          <Button
            {...triggerProps}
            data-testid="filters-popover-button"
            onClick={() => setIsOpen(true)}
            renderIcon={<IconFilterLine />}
          >
            {I18n.t('Filters')}
          </Button>
        </Badge>
      )}
    >
      <View as="div" padding="medium" width="22rem">
        <Flex justifyItems="space-between" alignItems="center" margin="0 0 large 0">
          <Heading level="h3" margin="0" data-testid="filters-popover-header">
            {I18n.t('Filter')}
          </Heading>
          <CloseButton screenReaderLabel={I18n.t('Close Filter Popover')} onClick={handleClose} />
        </Flex>
        <Flex as="div" direction="column" gap="medium">
          <FilterDropDown
            dataTestId="issue-type-dropdown"
            label={I18n.t('Issue Type')}
            options={issueTypeOptions}
            selected={selectedIssues}
            onChange={setSelectedIssues}
          />

          <FilterDropDown
            dataTestId="artifact-type-dropdown"
            label={I18n.t('Artifact Type')}
            options={artifactTypeOptions}
            selected={selectedArtifactType}
            onChange={setSelectedArtifactType}
          />

          <FilterDropDown
            dataTestId="state-dropdown"
            label={I18n.t('State')}
            options={stateOptions}
            selected={selectedState}
            onChange={setSelectedState}
          />
          <Flex as="div" direction="column" gap="small">
            <Text as="div" weight="weightImportant">
              {I18n.t('Date Range')}
            </Text>
            <CanvasDateInput2
              placeholder={I18n.t('From')}
              width="100%"
              selectedDate={fromDate?.value ?? null}
              formatDate={dateFormatter}
              interaction="enabled"
              renderLabel={I18n.t('From')}
              onSelectedDateChange={date => handleDateChange(date, setFromDate, I18n.t('From'))}
            />
            <CanvasDateInput2
              placeholder={I18n.t('To')}
              width="100%"
              selectedDate={toDate?.value ?? null}
              interaction="enabled"
              formatDate={dateFormatter}
              renderLabel={I18n.t('To')}
              onSelectedDateChange={date => handleDateChange(date, setToDate, I18n.t('To'))}
            />
          </Flex>
        </Flex>
      </View>
      <View as="div" background="secondary" padding="small">
        <Flex as="div" justifyItems="end" margin="0">
          <Button data-testid="reset-button" onClick={handleReset}>
            {I18n.t('Reset')}
          </Button>
        </Flex>
      </View>
    </Popover>
  )
}

export default FiltersPopover
