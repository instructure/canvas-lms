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
import I18n from 'i18n!assignments_2'
import _ from 'lodash'

import {View} from '@instructure/ui-layout'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import {TextInput} from '@instructure/ui-forms'

import {TeacherAssignmentShape} from '../assignmentData'
import StudentSearchQuery from './StudentSearchQuery'
import StudentsTable from './StudentsTable'

const STUDENT_SEARCH_DELAY = 750
const MIN_SEARCH_CHARS = 3
const SORTABLE_COLUMNS = ['username', 'score', 'submitted_at']

export default class StudentsSearcher extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      searchValue: '',
      debouncedSearchValue: '',
      sortId: '',
      sortDirection: 'none'
    }
  }

  static propTypes = {
    assignment: TeacherAssignmentShape.isRequired
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

  render() {
    const searchVariables = {
      assignmentId: this.props.assignment.lid
    }
    const searchMessages = []

    if (this.state.debouncedSearchValue.length >= MIN_SEARCH_CHARS) {
      searchVariables.userSearch = this.state.debouncedSearchValue
    } else if (this.state.debouncedSearchValue.length > 0) {
      searchMessages.push({
        text: I18n.t('Search term must be at least %{num} characters', {num: MIN_SEARCH_CHARS}),
        type: 'error'
      })
    }

    if (this.state.sortId !== '') {
      searchVariables.orderBy = [{field: this.state.sortId, direction: this.state.sortDirection}]
    }

    return (
      <React.Fragment>
        <View as="div" margin="0 0 large 0">
          <TextInput
            label={<ScreenReaderContent>{I18n.t('Search by student name')}</ScreenReaderContent>}
            placeholder={I18n.t('Search')}
            messages={searchMessages}
            onChange={this.handleNameFilterChange}
            value={this.state.searchValue}
          />
        </View>
        <StudentSearchQuery variables={searchVariables}>
          {submissions => (
            <StudentsTable
              assignment={this.props.assignment}
              submissions={submissions}
              sortableColumns={SORTABLE_COLUMNS}
              sortId={this.state.sortId}
              sortDirection={this.state.sortDirection}
              onRequestSort={this.handleRequestSort}
            />
          )}
        </StudentSearchQuery>
      </React.Fragment>
    )
  }
}
