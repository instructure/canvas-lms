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
export function propsFromState(state) {
  const ui = state.ui,
        containingContext = state.containingContext,
        contextType = state.contextType,
        contextId = state.contextId,
        files = state.files,
        images = state.images,
        documents = state.documents,
        media = state.media,
        folders = state.folders,
        rootFolderId = state.rootFolderId,
        flickr = state.flickr,
        upload = state.upload,
        session = state.session,
        newPageLinkExpanded = state.newPageLinkExpanded,
        all_files = state.all_files,
        jwt = state.jwt,
        host = state.host,
        source = state.source;
  const collections = {};

  for (const key in state.collections) {
    const collection = state.collections[key];
    collections[key] = collection;
  }

  return _objectSpread(_objectSpread({
    containingContext,
    contextType,
    contextId,
    collections,
    files,
    images,
    documents,
    media,
    folders,
    rootFolderId,
    flickr,
    upload,
    session,
    newPageLinkExpanded
  }, ui), {}, {
    all_files,
    jwt,
    host,
    source
  });
}