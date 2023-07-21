/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

const addSearchHighlighting = (searchTerm, searchArea, isIsolatedView) => {
  if (!!searchArea && !!searchTerm && !isIsolatedView) {
    const searchExpression = new RegExp(`(${searchTerm})`, 'gi')
    return searchArea
      .replace(/<[^>]*>?/gm, '')
      .replace(
        searchExpression,
        '<span data-testid="highlighted-search-item" style="background-color: rgba(0,142,226,0.2); border-radius: .25rem; padding-bottom: 3px; padding-top: 1px;">$1</span>'
      )
  }
  return searchArea
}

export function SearchSpan({...props}) {
  return (
    <span
      className="user_content"
      dangerouslySetInnerHTML={{
        __html: addSearchHighlighting(props.searchTerm, props.text, props.isIsolatedView),
      }}
    />
  )
}

SearchSpan.propTypes = {
  /**
   * String containing the term to highlight
   */
  searchTerm: PropTypes.string,
  /**
   * String containing displayable message
   */
  text: PropTypes.string.isRequired,
  isIsolatedView: PropTypes.bool,
}
