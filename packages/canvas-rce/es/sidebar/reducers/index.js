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
import noop from "./noop.js";
import uiReducer from "./ui.js";
import collectionsReducer from "./collections.js";
import files from "./files.js";
import folders from "./folders.js";
import rootFolderId from "./rootFolderId.js";
import imagesReducer from "./images.js";
import documentsReducer from "./documents.js";
import mediaReducer from "./media.js";
import upload from "./upload.js";
import flickrReducer from "./flickr.js";
import session from "./session.js";
import newPageLinkReducer from "./newPageLinkExpanded.js";
import { changeContextType, changeContextId, changeSearchString, changeSortBy } from "./filter.js";
import { allFilesLoading } from "./all_files.js";
import { combineReducers } from 'redux'; // combine for root level state.

export default combineReducers({
  ui: uiReducer,
  source: noop,
  jwt: noop,
  host: noop,
  containingContext: noop,
  contextType: changeContextType,
  contextId: changeContextId,
  searchString: changeSearchString,
  sortBy: changeSortBy,
  all_files: allFilesLoading,
  collections: collectionsReducer,
  files,
  folders,
  rootFolderId,
  images: imagesReducer,
  documents: documentsReducer,
  media: mediaReducer,
  upload,
  flickr: flickrReducer,
  session,
  newPageLinkExpanded: newPageLinkReducer
});