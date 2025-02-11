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

import React, {useEffect, useState, useCallback} from 'react'
import {connect} from 'react-redux'
import type {Dispatch} from 'redux'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {Checkbox} from '@instructure/ui-checkbox'
import {TextInput} from '@instructure/ui-text-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconSearchLine} from '@instructure/ui-icons'
import {Button} from '@instructure/ui-buttons'
import {Select} from '@instructure/ui-select'
import {Table} from '@instructure/ui-table'
import Paginator from '@canvas/instui-bindings/react/Paginator'
import {useScope as createI18nScope} from '@canvas/i18n'
import {coursePaceDateFormatter} from '../shared/api/backend_serializer'
import {actions} from '../actions/ui'
import type {SortableColumn, OrderType, StoreState, Section, Student} from '../types'

import {
  fetchStudents,
  setSearchTerm,
  setFilterSection,
  setFilterPaceStatus,
  setPage,
  setSort,
  resetBulkEditState
} from '../actions/bulk_edit_students_actions'
import {Tooltip} from '@instructure/ui-tooltip'
import moment from 'moment'
import {getSelectedBulkStudents} from '../reducers/ui'

interface StateProps {
  searchTerm: string
  filterSection: string
  filterPaceStatus: string
  sortBy: SortableColumn
  orderType: OrderType
  page: number
  pageCount: number
  students: Student[]
  sections: Section[]
  isLoading: boolean
  error?: string
  selectedBulkStudents: string[]
}


interface DispatchProps {
  fetchData: () => void
  onSearchTermChange: (term: string) => void
  onFilterSectionChange: (section: string) => void
  onFilterPaceStatusChange: (status: string) => void
  onSetPage: (page: number) => void
  onSetSort: (sortBy: SortableColumn, orderType: OrderType) => void
  setSelectedBulkStudents: (studentIds: string[]) => void
  resetBulkEditState: () => void
}

interface Props extends StateProps, DispatchProps {}


const I18n = createI18nScope('bulk_edit_students_table')

const BulkEditStudentsTableComponent = ({
  searchTerm,
  filterSection,
  filterPaceStatus,
  sortBy,
  orderType,
  page,
  pageCount,
  students,
  sections,
  isLoading,
  error,
  fetchData,
  onSearchTermChange,
  onFilterSectionChange,
  onFilterPaceStatusChange,
  onSetPage,
  onSetSort,
  setSelectedBulkStudents,
  selectedBulkStudents,
  resetBulkEditState
}: Props) => {

  useEffect(() => {
    fetchData()
  }, [
    searchTerm,
    filterSection,
    filterPaceStatus,
    sortBy,
    orderType,
    page,
    fetchData,
  ])


  const [sectionFilterIsShowingOptions, setSectionFilterIsShowingOptions] = React.useState<boolean>(false)
  const [sectionFilterSelectedOptionId, setSectionFilterSelectedOptionId] = React.useState<string | null>('all')
  const [sectionFilterHighlightedOptionId, setSectionFilterHighlightedOptionId] = React.useState<string | null>('')
  const [sectionFilterInputValue, setSectionFilterInputValue] = React.useState<any>(I18n.t('All Sections'))

  const [sectionOptions, setSectionOptions] = React.useState<Section[]>([])

  const [searchInput, setSearchInput] = useState(searchTerm)

  const dateFormatter = coursePaceDateFormatter()

  useEffect(() => {
    setSectionOptions(sections)
  }, [sections])

  useEffect(() => {
    return () => {
      onSearchTermChange('')
      setSectionFilterSelectedOptionId('all')
      setSectionFilterHighlightedOptionId('')
      setSectionFilterInputValue(I18n.t('All Sections'))
      resetBulkEditState()
    }
  }, [])

  const [paceStatusFilterIsShowingOptions, setPaceStatusFilterIsShowingOptions] = React.useState<boolean>(false)
  const [paceStatusFilterSelectedOptionId, setPaceStatusFilterSelectedOptionId] = React.useState<string | null>('all')
  const [paceStatusFilterHighlightedOptionId, setPaceStatusFilterHighlightedOptionId] = React.useState<string | null>('')
  const [paceStatusFilterInputValue, setPaceStatusFilterInputValue] = React.useState<any>(I18n.t('All Statuses'))

  const [firstDateSelected, setFirstDateSelected] = React.useState<string | null>(null)

  const paceStatusOptions = [
    {id: 'all', name: I18n.t('All Statuses')},
    {id: 'off-pace', name: I18n.t('Off Pace')},
    {id: 'on-pace', name: I18n.t('On Pace')},
  ]

  const handleSearch = (searchTerm: string) => {
    onSetPage(1)
    onSearchTermChange(searchTerm)
  }

  const renderSelectOptions = (
    optionsList: {id: string; name: string}[],
    highlightedOptionId: string | null,
    selectedOptionId: string | null
  ) => {
    return optionsList.map((option) => (
      <Select.Option
        id={option.id}
        key={option.id}
        isHighlighted={option.id === highlightedOptionId}
        isSelected={option.id === selectedOptionId}
      >
        {option.name}
      </Select.Option>
    ))
  }


  const getOptionById = (queryId: string | null, optionsList: {id: string, name: string}[]) => {
    return optionsList.find(({id}) => id === queryId)
  }

  const handleSelectOption = (event: any, {id}: {id?: string | undefined}, filterType: 'section' | 'paceStatus') => {
    const optionsList = filterType === 'section' ? sectionOptions : paceStatusOptions
    const optionName = getOptionById(id || '', optionsList)?.name

    if (filterType === 'section') {
      setSectionFilterSelectedOptionId(id || null)
      setSectionFilterInputValue(optionName)
      setSectionFilterIsShowingOptions(false)
      onFilterSectionChange(id || '')
    } else {
      setPaceStatusFilterSelectedOptionId(id || null)
      setPaceStatusFilterInputValue(optionName)
      setPaceStatusFilterIsShowingOptions(false)
      onFilterPaceStatusChange(id || '')
    }
  }


  const handleHighlightOption = (
    event: any,
    {id}: Partial<{id: string}>,
    filterType: 'section' | 'paceStatus'
  ) => {
    event.persist()
    const optionsList = filterType === 'section' ? sectionOptions : paceStatusOptions
    const optionName = getOptionById(id || '', optionsList)?.name

    if (filterType === 'section') {
      setSectionFilterHighlightedOptionId(id || '')
      setSectionFilterInputValue(event.type === 'keydown' ? optionName : sectionFilterInputValue)
    } else {
      setPaceStatusFilterHighlightedOptionId(id || '')
      setPaceStatusFilterInputValue(event.type === 'keydown' ? optionName : paceStatusFilterInputValue)
    }
  }

  const handleRowCheckbox = useCallback((student: Student, formattedEnrollmentDate: string) => {
    if (!firstDateSelected) setFirstDateSelected(formattedEnrollmentDate)

    const updatedSelection = new Set(selectedBulkStudents)
    if (updatedSelection.has(student.enrollmentId)) {
      updatedSelection.delete(student.enrollmentId)
    } else {
      updatedSelection.add(student.enrollmentId)
    }
    if (updatedSelection.size === 0) {
      setFirstDateSelected(null)
    }
    setSelectedBulkStudents(Array.from(updatedSelection))

  }, [selectedBulkStudents, firstDateSelected, setSelectedBulkStudents])

  const handleSearchChange = (value: string) => {
    setSearchInput(value)
  }

  const handleSortClick = (col: SortableColumn) => {
    if (sortBy === col) {
      const newOrder: OrderType = orderType === 'asc' ? 'desc' : 'asc'
      onSetSort(col, newOrder)
    } else {
      onSetSort(col, 'asc')
    }
  }
  return (
    <View  as="div" padding="small">
      {error && (
        <Text as="div" color="danger">
          {error}
        </Text>
      )}
        <Flex margin="small 0">
          <Flex.Item shouldGrow={true}>
          <TextInput
            renderLabel={<ScreenReaderContent>Search for students</ScreenReaderContent>}
            placeholder={I18n.t('Search for students...')}
            value={searchInput}
            onChange={(_event, value) => handleSearchChange(value)}
            onKeyDown={(event) => {
              if (event.key === 'Enter') {
                handleSearch(searchInput)
              }
            }}
            renderBeforeInput={<IconSearchLine inline={false} />}
          />
          </Flex.Item>
          <Flex.Item>
            <Button
              color="primary"
              margin="0 0 0 small"
              onClick={() => handleSearch(searchInput)}
              data-testid="search-button"
            >
              {I18n.t('Search')}
            </Button>
          </Flex.Item>
        </Flex>
      <View>
        <Flex gap="small" margin='medium 0'>
          <Flex.Item shouldGrow>
            <Select
              renderLabel="Filter Sections"
              inputValue={sectionFilterInputValue}
              isShowingOptions={sectionFilterIsShowingOptions}
              onRequestShowOptions={() => {setSectionFilterIsShowingOptions(true)}}
              onBlur={() => {setSectionFilterIsShowingOptions(false)}}
              onRequestSelectOption={(event, option) => handleSelectOption(event, option, 'section')}
              onRequestHighlightOption={(event, option) => handleHighlightOption(event, option, 'section')}
            >
              {renderSelectOptions(sectionOptions, sectionFilterHighlightedOptionId, sectionFilterSelectedOptionId)}
            </Select>
          </Flex.Item>
          <Flex.Item shouldGrow>
            <Select
              renderLabel="Filter Pace Status"
              inputValue={paceStatusFilterInputValue}
              isShowingOptions={paceStatusFilterIsShowingOptions}
              onRequestShowOptions={() => {setPaceStatusFilterIsShowingOptions(true)}}
              onBlur={() => {setPaceStatusFilterIsShowingOptions(false)}}
              onRequestSelectOption={(event, option) => handleSelectOption(event, option, 'paceStatus')}
              onRequestHighlightOption={(event, option) => handleHighlightOption(event, option, 'paceStatus')}
            >
              {renderSelectOptions(paceStatusOptions, paceStatusFilterHighlightedOptionId, paceStatusFilterSelectedOptionId)}
            </Select>
          </Flex.Item>
        </Flex>
      </View>

      <View as="div">
        <Flex margin="small 0" justifyItems="end">
          <Text>{`${selectedBulkStudents.length} student${selectedBulkStudents.length > 1 ? 's' : ''} selected`}</Text>
        </Flex>
        <Table
          caption="Students"
        >
          <Table.Head>
            <Table.Row>
              <Table.ColHeader id="select-col" width="3rem">
              </Table.ColHeader>
              <Table.ColHeader
                id="name-col"
                onClick={() => handleSortClick('name')}
                {...(sortBy === 'name' && {sortDirection: orderType === 'asc' ? 'ascending' : 'descending'})}
              >
                {I18n.t('Student Name')}
              </Table.ColHeader>
              <Table.ColHeader
                id="section-col"
              >
                {I18n.t('Section')}
              </Table.ColHeader>
              <Table.ColHeader
                id="enrollment-date-col"
              >
                {I18n.t('Enrollment Date')}
              </Table.ColHeader>
            </Table.Row>
          </Table.Head>

          <Table.Body>
            {isLoading ? (
              <Table.Row>
                <Table.Cell colSpan={4}>
                  <View as="div" textAlign="center">
                    {I18n.t('Loading')}...
                  </View>
                </Table.Cell>
              </Table.Row>
            ) : students.length === 0 ? (
              <Table.Row>
                <Table.Cell colSpan={4}>
                  <View as="div" textAlign="center">
                    {I18n.t('No results found')}
                  </View>
                </Table.Cell>
              </Table.Row>
            ) : (
              students.map((student, i) => {
                const enrollmentDate = moment(student.enrollmentDate)
                const formattedDate = dateFormatter(enrollmentDate.toDate())
                const rowChecked = selectedBulkStudents.includes(student.enrollmentId)
                const rowDisabled = firstDateSelected !== null && (firstDateSelected !== formattedDate)
                const rowTextColor = rowDisabled ? 'secondary' : 'primary'

                const checkBoxElement = (
                  <Checkbox
                    data-testid={`student-checkbox-${i}`}
                    label=''
                    checked={rowChecked}
                    onChange={() => handleRowCheckbox(student, formattedDate)}
                    disabled={rowDisabled}
                  />
                )
                const checkboxElement = rowDisabled ? (
                  <Tooltip
                  color="primary-inverse"
                  renderTip={I18n.t('Only students with default course paces and same enrollment dates can be edited in bulk')}
                  placement="top"
                  offsetX="5px"
                  themeOverride={{
                    fontSize: '13px'
                  }}
                  >
                    {checkBoxElement}
                  </Tooltip>
              ) : checkBoxElement
                return (
                  <Table.Row key={student.id}>
                    <Table.Cell>
                      {checkboxElement}
                    </Table.Cell>
                    <Table.Cell><Text color={rowTextColor}>{student.name}</Text></Table.Cell>
                    <Table.Cell><Text color={rowTextColor}>{student.sections.map(s => s.name).join(", ")}</Text></Table.Cell>
                    <Table.Cell><Text color={rowTextColor}>{formattedDate}</Text></Table.Cell>
                  </Table.Row>
                )
              })
            )}
          </Table.Body>
        </Table>
      </View>
      {pageCount > 1 && (
        <View margin='x-small'>
          <Paginator
            loadPage={(newPage) => onSetPage(newPage)}
            page={page}
            pageCount={pageCount}
          />
        </View>
      )}
    </View>
  )
}

const mapStateToProps = (state: StoreState): StateProps => ({
  searchTerm: state.bulkEditStudents.searchTerm,
  filterSection: state.bulkEditStudents.filterSection,
  filterPaceStatus: state.bulkEditStudents.filterPaceStatus,
  sortBy: state.bulkEditStudents.sortBy,
  orderType: state.bulkEditStudents.orderType,
  page: state.bulkEditStudents.page,
  pageCount: state.bulkEditStudents.pageCount,
  students: state.bulkEditStudents.students,
  sections: state.bulkEditStudents.sections,
  isLoading: state.bulkEditStudents.isLoading,
  error: state.bulkEditStudents.error,
  selectedBulkStudents: getSelectedBulkStudents(state)
})

const mapDispatchToProps = (dispatch: Dispatch): DispatchProps => ({
  fetchData: () => dispatch(fetchStudents() as any),
  onSearchTermChange: (term) => dispatch(setSearchTerm(term)),
  onFilterSectionChange: (section) => dispatch(setFilterSection(section)),
  onFilterPaceStatusChange: (status) => dispatch(setFilterPaceStatus(status)),
  onSetPage: (p) => dispatch(setPage(p)),
  onSetSort: (column, order) => dispatch(setSort(column, order)),
  setSelectedBulkStudents: (students: string[]) => dispatch(actions.setSelectedBulkStudents(students)),
  resetBulkEditState: () => dispatch(resetBulkEditState() as any),
})

export const BulkEditStudentsTable = connect(
  mapStateToProps,
  mapDispatchToProps
)(BulkEditStudentsTableComponent)
