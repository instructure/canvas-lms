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
import {shape, arrayOf, string, func} from 'prop-types'
import {debounce} from 'underscore'
import I18n from 'i18n!account_course_user_search'
import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent'
import CoursesStore from '../store/CoursesStore'
import TermsStore from '../store/TermsStore'
import AccountsTreeStore from '../store/AccountsTreeStore'
import CoursesList from './CoursesList'
import CoursesToolbar from './CoursesToolbar'
import SearchMessage from './SearchMessage'
import { SEARCH_DEBOUNCE_TIME } from './UsersPane'

const MIN_SEARCH_LENGTH = 3
const stores = [CoursesStore, TermsStore, AccountsTreeStore]

const defaultFilters = {
  enrollment_term_id: '',
  search_term: '',
  sort: 'sis_course_id',
  order: 'asc',
  search_by: 'course',
  page: null
}

class CoursesPane extends React.Component {
  static propTypes = {
    roles: arrayOf(shape({ id: string.isRequired })).isRequired,
    queryParams: shape().isRequired,
    onUpdateQueryParams: func.isRequired,
    accountId: string.isRequired
  }

  constructor () {
    super()

    this.state = {
      filters: defaultFilters,
      draftFilters: defaultFilters,
      errors: {},
      previousCourses: {
        data: [],
        loading: true
      }
    }

    // Doing this here because the class property version didn't work :(
    this.debouncedApplyFilters = debounce(this.onApplyFilters, SEARCH_DEBOUNCE_TIME)
  }

  componentWillMount () {
    stores.forEach(s => s.addChangeListener(this.refresh))
    const filters = Object.assign({}, defaultFilters, this.props.queryParams)
    this.setState({filters, draftFilters: filters})
  }

  componentDidMount () {
    this.fetchCourses()
    TermsStore.loadAll()
  }

  componentWillUnmount () {
    stores.forEach(s => s.removeChangeListener(this.refresh))
  }

  componentWillReceiveProps(nextProps) {
    const filters = Object.assign({}, defaultFilters, nextProps.queryParams)
    this.setState({filters, draftFilters: filters})
  }

  fetchCourses = () => {
    this.updateQueryString()
    CoursesStore.load(this.state.filters)
  }

  setPage = (page) => {
    this.setState({
      filters: {...this.state.filters, page},
      previousCourses: CoursesStore.get(this.state.filters)
    }, this.fetchCourses)
  }

  onUpdateFilters = (newFilters) => {
    this.setState({
      errors: {},
      draftFilters: Object.assign({page: null}, this.state.draftFilters, newFilters)
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
    const newOrder = (column === sort && order === 'asc') ? 'desc' : 'asc'

    const newFilters = Object.assign({}, this.state.filters, {
      sort: column,
      order: newOrder
    })
    this.setState({filters: newFilters, previousCourses: CoursesStore.get(this.state.filters)}, this.fetchCourses)
  }

  refresh = () => {
    this.forceUpdate()
  }

  updateQueryString = () => {
    const differences = Object.keys(this.state.filters).reduce((memo, key) => {
      const value = this.state.filters[key]
      if (value !== defaultFilters[key]) {
        return {...memo, [key]: value}
      }
      return memo
    }, {})
    this.props.onUpdateQueryParams(differences)
  }

  render () {
    const { filters, draftFilters, errors } = this.state
    let courses = CoursesStore.get(filters)
    if (!courses || !courses.data) {
      courses = this.state.previousCourses
    }
    const terms = TermsStore.get()
    const isLoading = !(courses && !courses.loading)

    return (
      <div>
        <ScreenReaderContent>
          <h1>{I18n.t('Courses')}</h1>
        </ScreenReaderContent>

        <CoursesToolbar
          onUpdateFilters={this.onUpdateFilters}
          onApplyFilters={this.onApplyFilters}
          terms={terms}
          isLoading={isLoading}
          errors={errors}
          draftFilters={draftFilters}
        />

        <CoursesList
          onChangeSort={this.onChangeSort}
          accountId={this.props.accountId}
          courses={courses.data}
          roles={this.props.roles}
          sort={filters.sort}
          order={filters.order}
        />

        <SearchMessage
          collection={courses}
          setPage={this.setPage}
          noneFoundMessage={I18n.t('No courses found')}
          dataType="Course"
        />
      </div>
    )
  }
}

export default CoursesPane
