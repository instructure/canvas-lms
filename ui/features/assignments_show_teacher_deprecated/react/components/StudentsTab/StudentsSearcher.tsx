/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {useScope as createI18nScope} from '@canvas/i18n'
import {debounce} from 'es-toolkit/compat'
import {func} from 'prop-types'

import {
  ScreenReaderContent,
  PresentationContent,
  AccessibleContent,
} from '@instructure/ui-a11y-content'
import {TextInput} from '@instructure/ui-text-input'
import {Button} from '@instructure/ui-buttons'
import {
  IconSearchLine,
  IconFilterLine,
  IconSpeedGraderLine,
  IconEmailLine,
} from '@instructure/ui-icons'
import {Badge} from '@instructure/ui-badge'

import {TeacherAssignmentShape} from '../../assignmentData'
import StudentSearchQuery from './StudentSearchQuery'
import StudentsTable from './StudentsTable'
import Filters from './Filters'
import {Flex} from '@instructure/ui-flex'

const I18n = createI18nScope('assignments_2')

const STUDENT_SEARCH_DELAY = 750
const MIN_SEARCH_CHARS = 3
const SORTABLE_COLUMNS = ['username', 'score', 'submitted_at']

// @ts-expect-error
function assignmentIsNew(assignment) {
  return !assignment.lid
}

// @ts-expect-error
function assignmentIsPublished(assignment) {
  return assignment.state === 'published'
}

export default class StudentsSearcher extends React.Component {
  static propTypes = {
    assignment: TeacherAssignmentShape.isRequired,
    onMessageStudentsClick: func,
  }

  static defaultProps = {
    onMessageStudentsClick: () => {},
  }

  // @ts-expect-error
  constructor(props) {
    super(props)

    // @ts-expect-error
    const attemptsCount = this.props.assignment.submissions.nodes.map(sub => {
      return sub.attempt
    })

    this.state = {
      searchValue: '',
      debouncedSearchValue: '',
      sortId: '',
      sortDirection: 'none',
      showFilters: false,
      assignToFilter: null,
      attemptFilter: null,
      statusFilter: null,
      numAttempts: Math.max(...attemptsCount),
    }
  }

  componentWillUnmount() {
    this.debouncedHandleNameFilterChange.cancel()
  }

  // @ts-expect-error
  handleNameFilterChange = event => {
    this.setState({searchValue: event.target.value})
    this.debouncedHandleNameFilterChange(event.target.value)
  }

  debouncedHandleNameFilterChange = debounce(newSearchValue => {
    this.setState({debouncedSearchValue: newSearchValue})
  }, STUDENT_SEARCH_DELAY)

  // @ts-expect-error
  handleRequestSort = (event, {id}) => {
    this.setState(state => {
      // @ts-expect-error
      if (state.sortId === id) {
        // @ts-expect-error
        return {sortDirection: state.sortDirection === 'ascending' ? 'descending' : 'ascending'}
      } else if (SORTABLE_COLUMNS.includes(id)) {
        return {sortId: id, sortDirection: 'ascending'}
      } else {
        return null
      }
    })
  }

  submissions() {
    // TODO: We will need to exhaust the submissions pagination for this to work correctly
    // @ts-expect-error
    return this.props.assignment.submissions.nodes
  }

  // @ts-expect-error
  readGradeableSubmissionsCount(count) {
    return (
      <AccessibleContent alt={I18n.t('You have %{count} submissions to grade', {count})}>
        {count}
      </AccessibleContent>
    )
  }

  renderSpeedGraderLink() {
    // @ts-expect-error
    const assignmentLid = this.props.assignment.lid
    // @ts-expect-error
    const courseLid = this.props.assignment.course.lid
    const speedgraderLink = `/courses/${courseLid}/gradebook/speed_grader?assignment_id=${assignmentLid}`

    return (
      <Badge
        key="speedgraderLink"
        // @ts-expect-error
        count={this.props.assignment.needsGradingCount}
        margin="0 small 0 0"
        formatOutput={this.readGradeableSubmissionsCount}
      >
        {/* @ts-expect-error */}
        <Button renderIcon={IconSpeedGraderLine} href={speedgraderLink} target="_blank">
          {I18n.t('SpeedGrader')}
        </Button>
      </Badge>
    )
  }

  renderMessageStudentsWhoButton() {
    return (
      <Button
        // @ts-expect-error
        disabled={this.props.assignment.anonymizeStudents}
        // @ts-expect-error
        renderIcon={IconEmailLine}
        key="messageStudentsWho"
        // @ts-expect-error
        onClick={this.props.onMessageStudentsClick}
      >
        {I18n.t('Message Students')}
      </Button>
    )
  }

  renderActions() {
    // @ts-expect-error
    if (assignmentIsNew(this.props.assignment) || !assignmentIsPublished(this.props.assignment)) {
      return null
    }

    return [this.renderSpeedGraderLink(), this.renderMessageStudentsWhoButton()]
  }

  toggleFilters = () => {
    this.setState(state => {
      // @ts-expect-error
      const newState = {showFilters: !state.showFilters}
      // @ts-expect-error
      if (state.showFilters) {
        // @ts-expect-error
        newState.assignToFilter = null
        // @ts-expect-error
        newState.attemptFilter = null
        // @ts-expect-error
        newState.statusFilter = null
      }
      return newState
    })
  }

  // @ts-expect-error
  updateFilters = (field, value) => {
    const key = `${field}Filter`
    this.setState({[key]: value})
  }

  render() {
    const searchVariables = {
      // @ts-expect-error
      assignmentId: this.props.assignment.lid,
    }
    const searchMessages = []

    // @ts-expect-error
    if (this.state.debouncedSearchValue.length >= MIN_SEARCH_CHARS) {
      // @ts-expect-error
      searchVariables.userSearch = this.state.debouncedSearchValue
      // @ts-expect-error
    } else if (this.state.debouncedSearchValue.length > 0) {
      searchMessages.push({
        text: I18n.t('Search term must be at least %{num} characters', {num: MIN_SEARCH_CHARS}),
        type: 'error',
      })
    }

    // @ts-expect-error
    if (this.state.sortId !== '') {
      // @ts-expect-error
      searchVariables.orderBy = [{field: this.state.sortId, direction: this.state.sortDirection}]
    }

    return (
      <>
        <Flex as="div" margin="0 0 medium 0" wrap="wrap">
          <Flex.Item shouldGrow={true} size="60%" margin="small 0 0 0">
            <TextInput
              renderLabel={
                <ScreenReaderContent>{I18n.t('Search by student name')}</ScreenReaderContent>
              }
              placeholder={I18n.t('Search')}
              type="search"
              display="inline-block"
              width="70%"
              // @ts-expect-error
              messages={searchMessages}
              onChange={this.handleNameFilterChange}
              // @ts-expect-error
              value={this.state.searchValue}
              renderAfterInput={<IconSearchLine />}
            />
            {/* @ts-expect-error */}
            <Button renderIcon={IconFilterLine} margin="0 small" onClick={this.toggleFilters}>
              <PresentationContent>{I18n.t('Filter')}</PresentationContent>
              <ScreenReaderContent>
                {/* @ts-expect-error */}
                {this.state.showFilters
                  ? I18n.t('disable extra filter options')
                  : I18n.t('enable extra filter options')}
              </ScreenReaderContent>
            </Button>
            {/* @ts-expect-error */}
            {this.state.showFilters && (
              <Filters
                onChange={this.updateFilters}
                // @ts-expect-error
                overrides={this.props.assignment.assignmentOverrides.nodes}
                // @ts-expect-error
                numAttempts={this.state.numAttempts}
              />
            )}
          </Flex.Item>
          <Flex.Item margin="small 0 0 0" align="start">
            {this.renderActions()}
          </Flex.Item>
        </Flex>

        <StudentSearchQuery variables={searchVariables}>
          {submissions => {
            return (
              <StudentsTable
                // @ts-expect-error
                assignment={this.props.assignment}
                submissions={submissions}
                sortableColumns={SORTABLE_COLUMNS}
                // @ts-expect-error
                sortId={this.state.sortId}
                // @ts-expect-error
                sortDirection={this.state.sortDirection}
                onRequestSort={this.handleRequestSort}
                // @ts-expect-error
                assignToFilter={this.state.assignToFilter}
                // @ts-expect-error
                attemptFilter={this.state.attemptFilter}
                // @ts-expect-error
                statusFilter={this.state.statusFilter}
              />
            )
          }}
        </StudentSearchQuery>
      </>
    )
  }
}
