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

// Highlights plaintext while not modifying any existing HTML or styling.
const addSearchHighlighting = (searchTerm, searchArea, isSplitView) => {
  // Check for conditions where highlighting should not be applied
  if (!searchArea || !searchTerm || isSplitView) {
    return searchArea
  }

  // If no HTML tags, bypass parsing for performance
  if(!searchArea.includes('<')) return highlightText(searchArea, searchTerm)

  const textAndTags = [] // Stores HTML tags and plaintext as separate elements
  const textAndTagsMatches = [] // Stores indexes of matched elements
  let tempString = ""

  // Parse the input to split HTML tags from plaintext elements
  for(let i = 0; i < searchArea.length; i++) {
    if(searchArea[i] === '<' && tempString) {
      // Check if the plaintext element contains the search term
      if(tempString.toLowerCase().includes(searchTerm.toLowerCase())) {
        textAndTagsMatches.push(textAndTags.length)
      }
      // Add the plaintext element to array and reset for the tag element
      textAndTags.push(tempString)
      tempString = searchArea[i]
    }
    else if(searchArea[i] === '>' || i === searchArea.length - 1) {
      // Add the tag element to array and reset for next element
      tempString += searchArea[i]
      textAndTags.push(tempString)
      tempString = ""
    }
    else
    {
      tempString += searchArea[i]
    }
  }

  textAndTagsMatches.forEach( (index) => {
    textAndTags[index] = highlightText(textAndTags[index], searchTerm)
  })

  return textAndTags.join("")
}

// Highlight the search term and remove HTML
const highlightText = (text, searchTerm) => {
  const escapedSearchTerm = searchTerm.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
  const searchExpression = new RegExp(`(${escapedSearchTerm})`, 'gi')

  return text
    .replace(/<[^>]*>/gm, '')
    .replace(
      searchExpression,
      '<span data-testid="highlighted-search-item" style="font-weight: bold; background-color: rgba(0,142,226,0.2); border-radius: .25rem; padding-bottom: 3px; padding-top: 1px;">$1</span>'
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
      lang={props.lang}
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
  /**
   * Language code if the span has been translated
   */
  lang: PropTypes.string,
}
