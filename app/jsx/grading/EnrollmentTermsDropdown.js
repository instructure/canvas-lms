/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import _ from 'underscore'
import I18n from 'i18n!grading_periods'

class EnrollmentTermsDropdown extends React.Component {
  static propTypes = {
    terms: PropTypes.array.isRequired,
    changeSelectedEnrollmentTerm: PropTypes.func.isRequired
  }

  sortedTerms = terms => {
    const dated = _.select(terms, term => term.startAt)
    const datedTermsSortedByStart = _.sortBy(dated, term => term.startAt).reverse()

    const undated = _.select(terms, term => !term.startAt)
    const undatedTermsSortedByCreate = _.sortBy(undated, term => term.createdAt).reverse()
    return datedTermsSortedByStart.concat(undatedTermsSortedByCreate)
  }

  termOptions = terms => {
    const allTermsOption = (
      <option key={0} value={0}>
        {I18n.t('All Terms')}
      </option>
    )
    const options = _.map(this.sortedTerms(terms), term => (
      <option key={term.id} value={term.id}>
        {term.displayName}
      </option>
    ))

    options.unshift(allTermsOption)
    return options
  }

  render() {
    return (
      <select
        className="EnrollmentTerms__dropdown ic-Input"
        name="enrollment_term"
        data-view="termSelect"
        aria-label="Enrollment Term"
        ref="termsDropdown"
        onChange={this.props.changeSelectedEnrollmentTerm}
      >
        {this.termOptions(this.props.terms)}
      </select>
    )
  }
}

export default EnrollmentTermsDropdown
