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

import React, {useRef} from 'react'
import {map, filter, sortBy} from 'lodash'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('EnrollmentTermsDropdown')

interface Term {
  id: string | number
  displayName: string
  startAt?: string
  createdAt: string
}

interface EnrollmentTermsDropdownProps {
  terms: Term[]
  changeSelectedEnrollmentTerm: (event: React.ChangeEvent<HTMLSelectElement>) => void
}

const EnrollmentTermsDropdown: React.FC<EnrollmentTermsDropdownProps> = ({
  terms,
  changeSelectedEnrollmentTerm,
}) => {
  const termsDropdownRef = useRef<HTMLSelectElement>(null)

  const sortedTerms = (termsList: Term[]): Term[] => {
    const dated = filter(termsList, (term): term is Term => !!term.startAt) as Term[]
    const datedTermsSortedByStart = sortBy(dated, term => term.startAt).reverse()

    const undated = filter(termsList, (term): term is Term => !term.startAt) as Term[]
    const undatedTermsSortedByCreate = sortBy(undated, term => term.createdAt).reverse()
    return datedTermsSortedByStart.concat(undatedTermsSortedByCreate)
  }

  const termOptions = (termsList: Term[]) => {
    const allTermsOption = (
      <option key={0} value={0}>
        {I18n.t('All Terms')}
      </option>
    )
    const options = map(sortedTerms(termsList), (term: Term) => (
      <option key={term.id} value={term.id}>
        {term.displayName}
      </option>
    ))

    options.unshift(allTermsOption)
    return options
  }

  return (
    <select
      className="EnrollmentTerms__dropdown ic-Input"
      name="enrollment_term"
      data-view="termSelect"
      data-testid="enrollment-terms-dropdown"
      aria-label="Enrollment Term"
      ref={termsDropdownRef}
      onChange={changeSelectedEnrollmentTerm}
    >
      {termOptions(terms)}
    </select>
  )
}

export default EnrollmentTermsDropdown
