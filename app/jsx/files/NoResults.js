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

import I18n from 'i18n!react_files'
import React from 'react'
import PropTypes from 'prop-types'

export default function NoResults({search_term}) {
  return (
    <div>
      <p ref="yourSearch">
        {I18n.t(
          'errors.no_match.your_search',
          'Your search - "%{search_term}" - did not match any files.',
          {search_term}
        )}
      </p>
      <p>{I18n.t('errors.no_match.suggestions', 'Suggestions:')}</p>
      <ul>
        <li>{I18n.t('errors.no_match.spelled', 'Make sure all words are spelled correctly.')}</li>
        <li>{I18n.t('errors.no_match.keywords', 'Try different keywords.')}</li>
        <li>
          {I18n.t('errors.no_match.three_chars', 'Enter at least 3 letters in the search box.')}
        </li>
      </ul>
    </div>
  )
}

NoResults.propTypes = {
  search_term: PropTypes.string
}
