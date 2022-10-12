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
import {useScope as useI18nScope} from '@canvas/i18n'
import _ from 'lodash'
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

const I18n = useI18nScope('assignments_2')

const STUDENT_SEARCH_DELAY = 750
const MIN_SEARCH_CHARS = 3
const SORTABLE_COLUMNS = ['username', 'score', 'submitted_at']

function assignmentIsNew(assignment) {
  return !assignment.lid
}

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

  constructor(props) {
    super(props)

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

  handleNameFilterChange = event => {
    this.setState({searchValue: event.target.value})
    this.debouncedHandleNameFilterChange(event.target.value)
  }

  debouncedHandleNameFilterChange = _.debounce(newSearchValue => {
    this.setState({debouncedSearchValue: newSearchValue})
  }, STUDENT_SEARCH_DELAY)

  handleRequestSort = (event, {id}) => {
    this.setState(state => {
      if (state.sortId === id) {
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
    return this.props.assignment.submissions.nodes
  }

  readGradeableSubmissionsCount(count) {
    return (
      <AccessibleContent alt={I18n.t('You have %{count} submissions to grade', {count})}>
        {count}
      </AccessibleContent>
    )
  }

  renderSpeedGraderLink() {
    const assignmentLid = this.props.assignment.lid
    const courseLid = this.props.assignment.course.lid
    const speedgraderLink = `/courses/${courseLid}/gradebook/speed_grader?assignment_id=${assignmentLid}`

    return (
      <Badge
        key="speedgraderLink"
        count={this.props.assignment.needsGradingCount}
        margin="0 small 0 0"
        formatOutput={this.readGradeableSubmissionsCount}
      >
        <Button renderIcon={IconSpeedGraderLine} href={speedgraderLink} target="_blank">
          {I18n.t('Speedgrader')}
        </Button>
      </Badge>
    )
  }

  renderMessageStudentsWhoButton() {
    return (
      <Button
        disabled={this.props.assignment.anonymizeStudents}
        renderIcon={IconEmailLine}
        key="messageStudentsWho"
        onClick={this.props.onMessageStudentsClick}
      >
        {I18n.t('Message Students')}
      </Button>
    )
  }

  renderActions() {
    if (assignmentIsNew(this.props.assignment) || !assignmentIsPublished(this.props.assignment)) {
      return null
    }

    return [this.renderSpeedGraderLink(), this.renderMessageStudentsWhoButton()]
  }

  toggleFilters = () => {
    this.setState(state => {
      const newState = {showFilters: !state.showFilters}
      if (state.showFilters) {
        newState.assignToFilter = null
        newState.attemptFilter = null
        newState.statusFilter = null
      }
      return newState
    })
  }

  updateFilters = (field, value) => {
    const key = `${field}Filter`
    this.setState({[key]: value})
  }

  render() {
    const searchVariables = {
      assignmentId: this.props.assignment.lid,
    }
    const searchMessages = []

    if (this.state.debouncedSearchValue.length >= MIN_SEARCH_CHARS) {
      searchVariables.userSearch = this.state.debouncedSearchValue
    } else if (this.state.debouncedSearchValue.length > 0) {
      searchMessages.push({
        text: I18n.t('Search term must be at least %{num} characters', {num: MIN_SEARCH_CHARS}),
        type: 'error',
      })
    }

    if (this.state.sortId !== '') {
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
              messages={searchMessages}
              onChange={this.handleNameFilterChange}
              value={this.state.searchValue}
              renderAfterInput={<IconSearchLine />}
            />
            <Button renderIcon={IconFilterLine} margin="0 small" onClick={this.toggleFilters}>
              <PresentationContent>{I18n.t('Filter')}</PresentationContent>
              <ScreenReaderContent>
                {this.state.showFilters
                  ? I18n.t('disable extra filter options')
                  : I18n.t('enable extra filter options')}
              </ScreenReaderContent>
            </Button>
            {this.state.showFilters && (
              <Filters
                onChange={this.updateFilters}
                overrides={this.props.assignment.assignmentOverrides.nodes}
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
                assignment={this.props.assignment}
                submissions={submissions}
                sortableColumns={SORTABLE_COLUMNS}
                sortId={this.state.sortId}
                sortDirection={this.state.sortDirection}
                onRequestSort={this.handleRequestSort}
                assignToFilter={this.state.assignToFilter}
                attemptFilter={this.state.attemptFilter}
                statusFilter={this.state.statusFilter}
              />
            )
          }}
        </StudentSearchQuery>
      </>
    )
  }
}
