/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import RceApiSource from '../../rcs/api'

// normalize contextType. e.g. accept either of 'course' or 'courses', but
// only store 'course'
function normalizeContextType(contextType) {
  switch (contextType) {
    case 'course':
    case 'courses':
      return 'course'
    case 'group':
    case 'groups':
      return 'group'
    case 'user':
    case 'users':
      return 'user'
    default:
      return undefined
  }
}

/* eslint-disable prefer-const */
export default function (props = {}) {
  let {
    source,
    jwt,
    refreshToken,
    host,
    contextType,
    contextId,
    collections,
    files,
    folders,
    upload,
    images,
    documents,
    media,
    flickr,
    newPageLinkExpanded,
    searchString,
    sortBy,
    all_files,
    canvasOrigin,
    canvasUrl,
  } = props
  /* eslint-enable prefer-const */

  if (!canvasOrigin) {
    canvasOrigin = canvasUrl
  }

  // normalize contextType (including in props)
  contextType = normalizeContextType(contextType)
  props = {...props, contextType}

  if (searchString === undefined) {
    searchString = ''
  }

  if (all_files === undefined) {
    all_files = {isLoading: false}
  }

  if (!sortBy) sortBy = {}
  sortBy = {sort: 'date_added', dir: 'desc', ...sortBy}

  // default to API source
  if (source == null) {
    source = new RceApiSource({
      jwt,
      refreshToken,
      host,
      canvasOrigin,
    })
  }

  // create collections in default state if none provided
  if (collections === undefined) {
    collections = {
      announcements: source.initializeCollection('announcements', props),
      assignments: source.initializeCollection('assignments', props),
      discussions: source.initializeCollection('discussions', props),
      modules: source.initializeCollection('modules', props),
      quizzes: source.initializeCollection('quizzes', props),
      wikiPages: source.initializeCollection('wikiPages', props),
    }
  }

  if (upload === undefined) {
    upload = source.initializeUpload(props)
  }

  if (flickr === undefined) {
    flickr = source.initializeFlickr(props)
  }

  if (images === undefined) {
    images = source.initializeImages(props)
  }

  if (documents === undefined) {
    documents = source.initializeDocuments(props)
  }

  if (media === undefined) {
    media = source.initializeMedia(props)
  }

  if (newPageLinkExpanded === undefined) {
    newPageLinkExpanded = false
  }
  function getAccordionIndex() {
    try {
      return window.sessionStorage.getItem('canvas_rce_links_accordion_index')
    } catch (err) {
      // If there is an error accessing session storage, just ignore it.
      // We are likely in a test environment
      return undefined
    }
  }
  const ui = {
    selectedAccordionIndex: getAccordionIndex(),
  }

  return {
    ui,
    source,
    jwt,
    host,
    contextType,
    contextId,
    collections,
    files,
    folders,
    upload,
    images,
    documents,
    media,
    flickr,
    newPageLinkExpanded,
    searchString,
    sortBy,
    all_files,
  }
}
