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

import noop from "./noop";
import uiReducer from "./ui";
import collectionsReducer from "./collections";
import files from "./files";
import folders from "./folders";
import rootFolderId from "./rootFolderId";
import imagesReducer from "./images";
import upload from "./upload";
import flickrReducer from "./flickr";
import session from "./session";
import newPageLinkReducer from "./newPageLinkExpanded";
import { combineReducers } from "redux";

// combine for root level state.
export default combineReducers({
  ui: uiReducer,
  source: noop,
  jwt: noop,
  host: noop,
  contextType: noop,
  contextId: noop,
  collections: collectionsReducer,
  files,
  folders,
  rootFolderId,
  images: imagesReducer,
  upload,
  flickr: flickrReducer,
  session,
  newPageLinkExpanded: newPageLinkReducer
});
