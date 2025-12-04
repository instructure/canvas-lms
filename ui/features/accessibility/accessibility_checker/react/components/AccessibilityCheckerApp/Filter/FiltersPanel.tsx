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

import React, {useState, useEffect, useCallback} from 'react'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconXLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {Responsive} from '@instructure/ui-responsive'
import {Heading} from '@instructure/ui-heading'
import CanvasDateInput2 from '@canvas/datetime/react/components/DateInput2'
import {useScope as createI18nScope} from '@canvas/i18n'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'

import {artifactTypeOptions, issueTypeOptions, stateOptions} from '../../../constants'
import {AppliedFilter, FilterOption, Filters} from '../../../../../shared/react/types'
import {useDateFormatPattern} from '../../../../../shared/react/hooks/useDateFormatPattern'
import {getAppliedFilters, getFilters} from '../../../utils'
import {responsiveQuerySizes} from '@canvas/breakpoints'
import FilterCheckboxGroup from './FilterCheckboxGroup'
import AppliedFilters from './AppliedFilters'
import CustomToggleGroup from './CustomToggleGroup'
import {Alert} from '@instructure/ui-alerts'
import getLiveRegion from '@canvas/instui-bindings/react/liveRegion'

const I18n = createI18nScope('accessibility_checker')

interface FiltersPanelProps {
  onFilterChange: (filters: null | Filters) => void
  appliedFilters?: AppliedFilter[]
}

const FiltersPanel: React.FC<FiltersPanelProps> = ({
  onFilterChange,
  appliedFilters = [],
}: FiltersPanelProps) => {
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
  const [alertMessage, setAlertMessage] = useState<string | null>(null)
  const toggleButtonRef = React.useRef<CustomToggleGroup | null>(null)

  const dateFormatter = useDateTimeFormat('date.formats.medium_with_weekday')
  const dateFormatHint = useDateFormatPattern()

  useEffect(() => {
    const filters = getFilters(appliedFilters)
    setSelectedIssues(filters.ruleTypes || [{label: 'all', value: 'all'}])
    setSelectedArtifactType(filters.artifactTypes || [{label: 'all', value: 'all'}])
    setSelectedState(filters.workflowStates || [{label: 'all', value: 'all'}])
    setFromDate(filters.fromDate || null)
    setToDate(filters.toDate || null)
    setFilterCount(appliedFilters.length)
  }, [appliedFilters])

  useEffect(() => {
    const timeout = setTimeout(() => {
      if (alertMessage !== null) {
        setAlertMessage(null)
      }
    }, 3000)

    return () => clearTimeout(timeout)
  }, [alertMessage, setAlertMessage])

  const getFilterSelections = useCallback((): Filters => {
    return {
      ruleTypes: selectedIssues,
      artifactTypes: selectedArtifactType,
      workflowStates: selectedState,
      fromDate: fromDate || null,
      toDate: toDate || null,
    }
  }, [fromDate, toDate, selectedArtifactType, selectedIssues, selectedState])

  const handleFilterChange = useCallback(
    (filters: Filters | null) => {
      onFilterChange(filters)

      const appliedFilters = getAppliedFilters(filters || {})

      const msg =
        appliedFilters.length > 0
          ? I18n.t('Filters applied. Accessibility issues updated.')
          : I18n.t('Filters cleared. Accessibility issues updated.')

      setTimeout(() => setAlertMessage(msg), 3000)
    },
    [onFilterChange],
  )

  const handleReset = useCallback(() => {
    setSelectedIssues([{label: 'all', value: 'all'}])
    setSelectedArtifactType([{label: 'all', value: 'all'}])
    setSelectedState([{label: 'all', value: 'all'}])
    setFromDate(null)
    setToDate(null)
    setFilterCount(0)
    handleFilterChange(null)
    setIsOpen(false)
  }, [handleFilterChange])

  const handleApply = useCallback(() => {
    const filters = getFilterSelections()
    setFilterCount(appliedFilters.length)
    handleFilterChange(filters)
    setIsOpen(false)
    toggleButtonRef.current?.focus()
  }, [appliedFilters, handleFilterChange, getFilterSelections])

  const handleDateChange = useCallback(
    (dateFieldId: 'fromDate' | 'toDate') => (date: Date | null) => {
      const setDate = dateFieldId === 'fromDate' ? setFromDate : setToDate
      if (!date) {
        setDate(null)
        return
      }
      setDate({label: dateFormatter(date), value: date.toISOString()})
    },
    [dateFormatter],
  )

  const handleToggle = useCallback(() => {
    setIsOpen(!isOpen)
    if (isOpen) {
      handleApply()
    }
  }, [isOpen, handleApply])

  return (
    <View
      as="div"
      borderColor="primary"
      borderWidth="small"
      borderRadius="medium"
      padding="x-small"
    >
      <CustomToggleGroup
        size="small"
        border={false}
        toggleLabel={I18n.t('Filter resources')}
        ref={e => (toggleButtonRef.current = e)}
        summary={
          <Responsive
            match="media"
            query={responsiveQuerySizes({tablet: true, desktop: true})}
            props={{
              tablet: {
                showTags: false,
                buttonText:
                  filterCount === 1
                    ? I18n.t('Clear 1 filter')
                    : I18n.t('Clear %{count} filters', {count: filterCount}),
                wrap: 'wrap',
              },
              desktop: {showTags: true, buttonText: I18n.t('Clear filters'), wrap: 'no-wrap'},
            }}
            render={props => {
              if (!props) return null
              return (
                <Flex gap="small" alignItems="start" wrap={props.wrap}>
                  <Flex.Item shouldGrow={!props.showTags} shouldShrink={false}>
                    <Heading level="h2" variant="label" margin="small 0">
                      {I18n.t('Filter resources')}
                    </Heading>
                  </Flex.Item>
                  {props.showTags && (
                    <Flex.Item shouldGrow={true} shouldShrink={true}>
                      <AppliedFilters
                        appliedFilters={appliedFilters}
                        setFilters={handleFilterChange}
                      />
                    </Flex.Item>
                  )}
                  {filterCount > 0 && (
                    <Flex.Item shouldGrow={false} shouldShrink={false}>
                      <Button
                        data-testid="clear-filters-button"
                        size="small"
                        onClick={handleReset}
                        renderIcon={<IconXLine />}
                        color="secondary"
                        margin="x-small 0 0 0"
                      >
                        {props.buttonText}
                      </Button>
                    </Flex.Item>
                  )}
                </Flex>
              )
            }}
          />
        }
        onToggle={handleToggle}
        expanded={isOpen}
      >
        <Responsive
          match="media"
          query={responsiveQuerySizes({tablet: true, desktop: true})}
          props={{
            tablet: {outerDirection: 'column', checkboxDirection: 'row'},
            desktop: {outerDirection: 'row', checkboxDirection: 'row'},
          }}
          render={props => {
            if (!props) return null
            return (
              <>
                <Flex
                  as="div"
                  direction={props.outerDirection}
                  gap="medium"
                  wrap="wrap"
                  alignItems="start"
                  padding="x-small"
                >
                  {/* Date inputs group - always vertical */}
                  <Flex.Item height="auto" overflowY="visible">
                    <Flex direction="column" gap="medium">
                      <Flex.Item overflowY="visible" height="auto">
                        <CanvasDateInput2
                          placeholder={I18n.t('From')}
                          messages={[
                            {
                              type: 'hint',
                              text: I18n.t('Expected format: %{format}', {format: dateFormatHint}),
                            },
                          ]}
                          width="100%"
                          selectedDate={fromDate?.value ?? null}
                          formatDate={dateFormatter}
                          interaction="enabled"
                          renderLabel={I18n.t('Last edited from')}
                          screenReaderLabels={{
                            calendarIcon: I18n.t('Choose a date for Last edited from'),
                          }}
                          onSelectedDateChange={handleDateChange('fromDate')}
                        />
                      </Flex.Item>
                      <Flex.Item overflowY="visible" height="auto">
                        <CanvasDateInput2
                          placeholder={I18n.t('To')}
                          messages={[
                            {
                              type: 'hint',
                              text: I18n.t('Expected format: %{format}', {format: dateFormatHint}),
                            },
                          ]}
                          width="100%"
                          selectedDate={toDate?.value ?? null}
                          interaction="enabled"
                          formatDate={dateFormatter}
                          renderLabel={I18n.t('Last edited to')}
                          screenReaderLabels={{
                            calendarIcon: I18n.t('Choose a date for Last edited to'),
                          }}
                          onSelectedDateChange={handleDateChange('toDate')}
                        />
                      </Flex.Item>
                    </Flex>
                  </Flex.Item>

                  {/* Checkbox group - responsive direction */}
                  <Flex.Item shouldGrow height="auto">
                    <Flex
                      direction={props.checkboxDirection}
                      gap="medium"
                      wrap="wrap"
                      alignItems="start"
                    >
                      <Flex.Item>
                        <FilterCheckboxGroup
                          data-testid="resource-type-checkbox-group"
                          name="resource-type-checkbox-group"
                          description={I18n.t('Resource type')}
                          options={artifactTypeOptions}
                          selected={selectedArtifactType}
                          onUpdate={setSelectedArtifactType}
                        />
                      </Flex.Item>
                      <Flex.Item>
                        <FilterCheckboxGroup
                          data-testid="state-checkbox-group"
                          name="state-checkbox-group"
                          description={I18n.t('State')}
                          options={stateOptions}
                          selected={selectedState}
                          onUpdate={setSelectedState}
                        />
                      </Flex.Item>
                      <Flex.Item>
                        <FilterCheckboxGroup
                          data-testid="issue-type-checkbox-group"
                          name="issue-type-checkbox-group"
                          description={I18n.t('With issues of')}
                          options={issueTypeOptions}
                          selected={selectedIssues}
                          onUpdate={setSelectedIssues}
                        />
                      </Flex.Item>
                    </Flex>
                  </Flex.Item>
                </Flex>

                {/* Apply filters button - separate Flex */}
                <Flex direction="row" justifyItems="end" padding="x-small">
                  <Flex.Item>
                    <Button
                      data-testid="apply-filters-button"
                      size="medium"
                      onClick={handleApply}
                      color="primary"
                    >
                      {I18n.t('Apply filters')}
                    </Button>
                  </Flex.Item>
                </Flex>
              </>
            )
          }}
        />
      </CustomToggleGroup>
      {alertMessage && (
        <Alert
          liveRegion={getLiveRegion}
          liveRegionPoliteness="assertive"
          isLiveRegionAtomic
          screenReaderOnly
        >
          {alertMessage}
        </Alert>
      )}
    </View>
  )
}

export default FiltersPanel
