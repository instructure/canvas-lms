import _objectSpread from "@babel/runtime/helpers/esm/objectSpread2";

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
import RceApiSource from "../sources/api.js"; // normalize contextType. e.g. accept either of 'course' or 'courses', but
// only store 'course'

function normalizeContextType(contextType) {
  switch (contextType) {
    case 'course':
    case 'courses':
      return 'course';

    case 'group':
    case 'groups':
      return 'group';

    case 'user':
    case 'users':
      return 'user';

    default:
      return void 0;
  }
}
/* eslint-disable prefer-const */


export default function (props = {}) {
  let _props = props,
      source = _props.source,
      jwt = _props.jwt,
      refreshToken = _props.refreshToken,
      host = _props.host,
      contextType = _props.contextType,
      contextId = _props.contextId,
      collections = _props.collections,
      files = _props.files,
      folders = _props.folders,
      upload = _props.upload,
      images = _props.images,
      documents = _props.documents,
      media = _props.media,
      flickr = _props.flickr,
      newPageLinkExpanded = _props.newPageLinkExpanded,
      searchString = _props.searchString,
      sortBy = _props.sortBy,
      all_files = _props.all_files;
  /* eslint-enable prefer-const */
  // normalize contextType (including in props)

  contextType = normalizeContextType(contextType);
  props = _objectSpread(_objectSpread({}, props), {}, {
    contextType
  });

  if (searchString === void 0) {
    searchString = '';
  }

  if (all_files === void 0) {
    all_files = {
      isLoading: false
    };
  }

  if (!sortBy) sortBy = {};
  sortBy = _objectSpread({
    sort: 'date_added',
    dir: 'desc'
  }, sortBy); // default to API source

  if (source == null) {
    source = new RceApiSource({
      jwt,
      refreshToken,
      host
    });
  } // create collections in default state if none provided


  if (collections === void 0) {
    collections = {
      announcements: source.initializeCollection('announcements', props),
      assignments: source.initializeCollection('assignments', props),
      discussions: source.initializeCollection('discussions', props),
      modules: source.initializeCollection('modules', props),
      quizzes: source.initializeCollection('quizzes', props),
      wikiPages: source.initializeCollection('wikiPages', props)
    };
  }

  if (upload === void 0) {
    upload = source.initializeUpload(props);
  }

  if (flickr === void 0) {
    flickr = source.initializeFlickr(props);
  }

  if (images === void 0) {
    images = source.initializeImages(props);
  }

  if (documents === void 0) {
    documents = source.initializeDocuments(props);
  }

  if (media === void 0) {
    media = source.initializeMedia(props);
  }

  if (newPageLinkExpanded === void 0) {
    newPageLinkExpanded = false;
  }

  const ui = {
    selectedAccordionIndex: function () {
      try {
        return window.sessionStorage.getItem('canvas_rce_links_accordion_index');
      } catch (err) {
        // If there is an error accessing session storage, just ignore it.
        // We are likely in a test environment
        return void 0;
      }
    }()
  };
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
    all_files
  };
}