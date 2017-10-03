/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import PropTypes from 'prop-types'
import { debounce } from 'underscore'
import I18n from 'i18n!account_course_user_search'
import CoursesStore from './CoursesStore'
import TermsStore from './TermsStore'
import AccountsTreeStore from './AccountsTreeStore'
import CoursesList from './CoursesList'
import CoursesToolbar from './CoursesToolbar'
import renderSearchMessage from './renderSearchMessage'

const MIN_SEARCH_LENGTH = 3
const stores = [CoursesStore, TermsStore, AccountsTreeStore]
const { shape, arrayOf, string } = PropTypes

class CoursesPane extends React.Component {
  static propTypes = {
    roles: arrayOf(shape({ id: string.isRequired })).isRequired,
    addUserUrls: shape({
      USER_LISTS_URL: string.isRequired,
      ENROLL_USERS_URL: string.isRequired,
    }).isRequired,
    accountId: string.isRequired,
  }

  constructor () {
    super()

    const filters = {
      enrollment_term_id: '',
      search_term: '',
      with_students: false,
      sort: 'sis_course_id',
      order: 'asc',
      search_by: 'course',
    }

    this.state = {
      filters,
      draftFilters: filters,
      errors: {},
      previousCourses: {data: []},
    }

    // Doing this here because the class property version didn't work :(
    this.debouncedApplyFilters = debounce(this.onApplyFilters, 250)
  }

  componentWillMount () {
    stores.forEach(s => s.addChangeListener(this.refresh))
  }

  componentDidMount () {
    this.fetchCourses()
    TermsStore.loadAll()
    AccountsTreeStore.loadTree()
  }

  componentWillUnmount () {
    stores.forEach(s => s.removeChangeListener(this.refresh))
  }

  fetchCourses = () => {
    CoursesStore.load(this.state.filters)
  }

  fetchMoreCourses = () => {
    CoursesStore.loadMore(this.state.filters)
  }

  onUpdateFilters = (newFilters) => {
    this.setState({
      errors: {},
      draftFilters: Object.assign({}, this.state.draftFilters, newFilters)
    }, this.debouncedApplyFilters)
  }

  onApplyFilters = () => {
    const filters = this.state.draftFilters
    if (filters.search_term && filters.search_term.length < MIN_SEARCH_LENGTH) {
      this.setState({errors: {search_term: I18n.t('Search term must be at least %{num} characters', {num: MIN_SEARCH_LENGTH})}})
    } else {
      this.setState({filters, errors: {}}, this.fetchCourses)
    }
  }

  onChangeSort = (column) => {
    const {sort, order} = this.state.filters
    let newOrder = 'asc'

    if (column === sort && order === 'asc') {
      newOrder = 'desc'
    }

    const newFilters = Object.assign({}, this.state.filters, {
      sort: column,
      order: newOrder
    })
    this.setState({filters: newFilters, previousCourses: CoursesStore.get(this.state.filters)}, this.fetchCourses)
  }

  refresh = () => {
    this.forceUpdate()
  }

  render () {
    const { filters, draftFilters, errors } = this.state
    let courses = CoursesStore.get(filters)
    if (!courses || !courses.data) {
      courses = this.state.previousCourses
    }
    const terms = TermsStore.get()
    const accounts = AccountsTreeStore.getTree()
    const isLoading = !(courses && !courses.loading && terms && !terms.loading)

    return (
      <div>
        <CoursesToolbar
          onUpdateFilters={this.onUpdateFilters}
          onApplyFilters={this.onApplyFilters}
          terms={terms && terms.data}
          accounts={accounts}
          isLoading={isLoading}
          {...draftFilters}
          errors={errors}
        />

        <CoursesList
          onChangeSort={this.onChangeSort}
          accountId={this.props.accountId}
          courses={courses.data}
          roles={this.props.roles}
          addUserUrls={this.props.addUserUrls}
          sort={filters.sort}
          order={filters.order}
        />

        {renderSearchMessage(courses, this.fetchMoreCourses, I18n.t('No courses found'))}
      </div>
    )
  }
}

export default CoursesPane
