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

import RceApiSource from "../sources/api";

// normalize contextType. e.g. accept either of 'course' or 'courses', but
// only store 'course'
function normalizeContextType(contextType) {
  switch (contextType) {
    case "course":
    case "courses":
      return "course";
    case "group":
    case "groups":
      return "group";
    case "user":
    case "users":
      return "user";
    default:
      return undefined;
  }
}

export default function(props = {}) {
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
    flickr,
    newPageLinkExpanded
  } = props;

  // normalize contextType (including in props)
  contextType = normalizeContextType(contextType);
  props = { ...props, contextType };

  // default to API source
  if (source === undefined) {
    source = new RceApiSource({
      jwt: jwt,
      refreshToken: refreshToken,
      host: host
    });
  }

  // create collections in default state if none provided
  if (collections === undefined) {
    collections = {
      announcements: source.initializeCollection("announcements", props),
      assignments: source.initializeCollection("assignments", props),
      discussions: source.initializeCollection("discussions", props),
      modules: source.initializeCollection("modules", props),
      quizzes: source.initializeCollection("quizzes", props),
      wikiPages: source.initializeCollection("wikiPages", props)
    };
  }

  if (upload === undefined) {
    upload = source.initializeUpload(props);
  }

  if (flickr === undefined) {
    flickr = source.initializeFlickr(props);
  }

  if (images === undefined) {
    images = source.initializeImages(props);
  }

  if (newPageLinkExpanded === undefined) {
    newPageLinkExpanded = false;
  }

  return {
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
    flickr,
    newPageLinkExpanded
  };
}
