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
import { string, bool, func, arrayOf, shape, oneOf } from 'prop-types'
import I18n from 'i18n!account_course_user_search'
import preventDefault from 'compiled/fn/preventDefault'
import TermsStore from './TermsStore'
import AccountsTreeStore from './AccountsTreeStore'
import NewCourseModal from './NewCourseModal'
import IcInput from './IcInput'
import IcSelect from './IcSelect'
import IcCheckbox from './IcCheckbox'

const TermOpts = ({terms}) => {
  return terms ? (
    <optgroup label={I18n.t('Show courses from')}>
      <option key="all" value="">
        {I18n.t('All Terms')}
      </option>
      {terms.map(term =>
        <option key={term.id} value={term.id}>
          {term.name}
        </option>
      )}
    </optgroup>
  ) : (
    <option value="">{I18n.t('Loading...')}</option>
  )
}
TermOpts.propTypes = { terms: arrayOf(TermsStore.PropType) }

export default class CoursesToolbar extends React.Component {
  static propTypes = {
    onUpdateFilters: func.isRequired,
    onApplyFilters: func.isRequired,
    isLoading: bool.isRequired,
    draftFilters: shape({
      with_students: bool.isRequired,
      search_by: oneOf(['course', 'teacher']).isRequired,
      search_term: string.isRequired,
      enrollment_term_id: string.isRequired,
    }).isRequired,
    errors: shape({ search_term: string }).isRequired,
    terms: arrayOf(TermsStore.PropType),
    accounts: arrayOf(AccountsTreeStore.PropType),
  }

  static defaultProps = {
    terms: null,
    accounts: [],
    isLoading: false,
  }

  addCourse = () => {
    this.addCourseModal.openModal()
  }

  render () {
    const { terms, accounts, onUpdateFilters, isLoading, errors, draftFilters} = this.props

    const addCourseButton = window.ENV.PERMISSIONS.can_create_courses ?
        (<div>
          <button className="Button selenium-spec-add-course-button" type="button" onClick={this.addCourse}>
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
          onSubmit={preventDefault(this.props.onApplyFilters)}
          disabled={isLoading}
        >
          <div className="ic-Form-action-box courses-list-search-bar-layout">
            <div className="ic-Form-action-box__Form">
              <IcSelect
                value={draftFilters.enrollment_term_id}
                onChange={e => onUpdateFilters({enrollment_term_id: e.target.value})}
              >
                <TermOpts terms={terms} />
              </IcSelect>
              <IcSelect
                value={draftFilters.search_by}
                onChange={e => onUpdateFilters({search_by: e.target.value})}
              >
                <optgroup label={I18n.t('Search By')}>
                  <option key="course" value="course">
                    {I18n.t('Course')}
                  </option>
                  <option key="teacher" value="teacher">
                    {I18n.t('Teacher')}
                  </option>
                </optgroup>
              </IcSelect>
              <IcInput
                value={draftFilters.search_term}
                placeholder={draftFilters.search_by === 'teacher' ?
                  I18n.t('Search courses by teacher...') :
                  I18n.t('Search courses...')
                }
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
            checked={draftFilters.with_students}
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

