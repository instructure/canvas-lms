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

// add highlighting and remove HTML from all incoming text
// with the exception of anything within the <iframe></iframe> HTML tag
const addSearchHighlighting = (searchTerm, searchArea, isSplitView) => {
  // Check for conditions where highlighting should not be applied
  if (!searchArea || !searchTerm || isSplitView) {
    return searchArea
  }

  let cursor = 0 // Initialize cursor to keep track of position in searchArea
  const iframePattern = /<iframe[\s\S]*?<\/iframe>/gi // Regular expression to match <iframe> elements

  // Get an array of all matches using matchAll, then process them
  const iframeMatches = Array.from(searchArea.matchAll(iframePattern))
  const modifiedHtml = iframeMatches
    .map(iframeMatch => {
      const startIndexOfIframeHtml = iframeMatch.index
      const endIndexOfIframeHtml = startIndexOfIframeHtml + iframeMatch[0].length
      const highlightedPart = highlightText(
        searchArea.substring(cursor, startIndexOfIframeHtml),
        searchTerm
      )
      cursor = endIndexOfIframeHtml
      // Construct modified HTML for this match
      return `${highlightedPart}<br>${iframeMatch[0]}<br>`
    })
    .join('') // Join all modified HTML strings into a single string

  // Highlight any remaining text after the last match
  return modifiedHtml + highlightText(searchArea.substring(cursor), searchTerm)
}

// Highlight the search term and remove HTML
const highlightText = (text, searchTerm) => {
  const escapedSearchTerm = searchTerm.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
  const searchExpression = new RegExp(`(${escapedSearchTerm})`, 'gi')

  return text
    .replace(/<[^>]*>/gm, '')
    .replace(
      searchExpression,
      '<span data-testid="highlighted-search-item" style="background-color: rgba(0,142,226,0.2); border-radius: .25rem; padding-bottom: 3px; padding-top: 1px;">$1</span>'
    )
}

export function SearchSpan({...props}) {
  const resourceType = () => {
    if (props.isAnnouncement == null || props.isTopic == null) {
      return undefined
    }

    return `${props.isAnnouncement ? 'announcement' : 'discussion_topic'}.${
      props.isTopic ? 'body' : 'reply'
    }`
  }

  return (
    <span
      className="user_content"
      data-resource-type={resourceType()}
      data-resource-id={props.resourceId}
      dangerouslySetInnerHTML={{
        __html: addSearchHighlighting(props.searchTerm, props.text, props.isSplitView),
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
  isSplitView: PropTypes.bool,
  isAnnouncement: PropTypes.bool,
  isTopic: PropTypes.bool,
  resourceId: PropTypes.string,
}
