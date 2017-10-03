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
import I18n from 'i18n!account_course_user_search'
import TermsStore from './TermsStore'
import AccountsTreeStore from './AccountsTreeStore'
import NewCourseModal from './NewCourseModal'
import IcInput from './IcInput'
import IcSelect from './IcSelect'
import IcCheckbox from './IcCheckbox'

const { string, bool, func, arrayOf, shape } = PropTypes

class CoursesToolbar extends React.Component {
  static propTypes = {
    onUpdateFilters: func.isRequired,
    onApplyFilters: func.isRequired,
    isLoading: bool,
    with_students: bool.isRequired,
    search_term: string,
    enrollment_term_id: string,
    sortColumn: string,
    errors: shape({ search_term: string }).isRequired,
    terms: arrayOf(TermsStore.PropType),
    accounts: arrayOf(AccountsTreeStore.PropType),
  }

  static defaultProps = {
    terms: null,
    accounts: [],
    search_term: '',
    enrollment_term_id: null,
    isLoading: false,
    sortColumn: ''
  }

  applyFilters = (e) => {
    e.preventDefault()
    this.props.onApplyFilters()
  }

  addCourse = () => {
    this.addCourseModal.openModal()
  }

  renderTerms () {
    const { terms } = this.props

    if (terms) {
      return [
        <option key="all" value="">
          {I18n.t('All Terms')}
        </option>
      ].concat(terms.map(term => (
        <option key={term.id} value={term.id}>
          {term.name}
        </option>
        )))
    }

    return <option value="">{I18n.t('Loading...')}</option>
  }

  render () {
    const { terms, accounts, onUpdateFilters, isLoading, errors, ...props } = this.props


    const addCourseButton = window.ENV.PERMISSIONS.can_create_courses ?
        (<div>
          <button className="btn" type="button" onClick={this.addCourse}>
            <i className="icon-plus" />
            {' '}
            {I18n.t('Course')}
          </button>
        </div>) : null

    return (
      <div>
        <form
          className="course_search_bar"
          style={{opacity: isLoading ? 0.5 : 1}}
          onSubmit={this.applyFilters}
          disabled={isLoading}
        >
          <div className="ic-Form-action-box courses-list-search-bar-layout">
            <div className="ic-Form-action-box__Form">
              <IcSelect
                value={props.enrollment_term_id}
                onChange={e => onUpdateFilters({enrollment_term_id: e.target.value})}
              >
                {this.renderTerms()}
              </IcSelect>
              <IcSelect
                value={props.search_by}
                onChange={e => onUpdateFilters({search_by: e.target.value})}
              >
                <option key="course" value="course">
                  {I18n.t('Course')}
                </option>
                <option key="teacher" value="teacher">
                  {I18n.t('Teacher')}
                </option>
              </IcSelect>
              <IcInput
                value={props.search_term}
                placeholder={I18n.t('Search courses...')}
                onChange={e => onUpdateFilters({search_term: e.target.value})}
                error={errors.search_term}
                type="search"
              />
            </div>
            <div className="ic-Form-action-box__Actions">
              {addCourseButton}
            </div>
          </div>
          <IcCheckbox
            checked={props.with_students}
            onChange={e => onUpdateFilters({with_students: e.target.checked})}
            label={I18n.t('Hide courses without enrollments')}
          />
        </form>
        <NewCourseModal
          ref={(c) => { this.addCourseModal = c }}
          terms={terms}
          accounts={accounts}
        />
      </div>
    )
  }
}

export default CoursesToolbar
