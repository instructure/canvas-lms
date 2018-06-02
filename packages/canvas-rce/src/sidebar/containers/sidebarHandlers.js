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

import { changeTab, changeAccordion } from "../actions/ui";
import { fetchInitialPage, fetchNextPage } from "../actions/data";
import { fetchImages } from "../actions/images";
import {
  fetchFolders,
  uploadPreflight,
  openOrCloseUploadForm
} from "../actions/upload";
import { searchFlickr, openOrCloseFlickrForm } from "../actions/flickr";
import { toggle as toggleFolder } from "../actions/files";
import { openOrCloseNewPageForm } from "../actions/links";

export default function propsFromDispatch(dispatch) {
  return {
    onChangeTab: index => dispatch(changeTab(index)),
    onChangeAccordion: index => dispatch(changeAccordion(index)),
    fetchInitialPage: key => dispatch(fetchInitialPage(key)),
    fetchNextPage: key => dispatch(fetchNextPage(key)),
    toggleFolder: id => dispatch(toggleFolder(id)),
    fetchFolders: () => dispatch(fetchFolders()),
    fetchImages: calledFromRender => dispatch(fetchImages(calledFromRender)),
    startUpload: (tabContext, fileMetaProps) =>
      dispatch(uploadPreflight(tabContext, fileMetaProps)),
    flickrSearch: term => dispatch(searchFlickr(term)),
    toggleFlickrForm: () => dispatch(openOrCloseFlickrForm()),
    toggleUploadForm: () => dispatch(openOrCloseUploadForm()),
    toggleNewPageForm: () => dispatch(openOrCloseNewPageForm())
  };
}
