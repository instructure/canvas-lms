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

import Sidebar from "../components/Sidebar";
import sidebarHandlers from "./sidebarHandlers";
import { connect } from "react-redux";

function propsFromState(state) {
  let {
    ui,
    contextType,
    contextId,
    files,
    images,
    folders,
    rootFolderId,
    flickr,
    upload,
    session,
    newPageLinkExpanded
  } = state;

  let collections = {};
  for (const key in state.collections) {
    let collection = state.collections[key];
    collections[key] = {
      links: collection.links,
      lastError: collection.error,
      isLoading: !!collection.loading,
      hasMore: !!collection.bookmark
    };
  }

  return Object.assign(
    {},
    {
      contextType,
      contextId,
      collections,
      files,
      images,
      folders,
      rootFolderId,
      flickr,
      upload,
      session,
      newPageLinkExpanded
    },
    ui
  );
}

export default connect(propsFromState, sidebarHandlers)(Sidebar);
