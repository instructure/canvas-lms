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

import {changeTab, changeAccordion} from '../actions/ui'
import {fetchInitialPage, fetchNextPage} from '../actions/data'
import {fetchInitialImages, fetchNextImages} from '../actions/images'
import {
  createMediaServerSession,
  fetchFolders,
  openOrCloseUploadForm,
  // saveMediaRecording,
  mediaUploadComplete,
  uploadPreflight,
  uploadToIconMakerFolder,
  uploadToMediaFolder,
} from '../actions/upload'
import {searchFlickr, openOrCloseFlickrForm} from '../actions/flickr'
import {toggle as toggleFolder} from '../actions/files'
import {openOrCloseNewPageForm} from '../actions/links'
import {fetchInitialDocs, fetchNextDocs} from '../actions/documents'
import {fetchInitialMedia, fetchNextMedia, updateMediaObject} from '../actions/media'
import {changeContext, changeSearchString, changeSortBy} from '../actions/filter'
import {allFilesLoading} from '../actions/all_files'
import {get as getSession} from '../actions/session'

const DEFAULT_FILE_CATEGORY = 'uncategorized'

export default function propsFromDispatch(dispatch) {
  return {
    loadSession: () => dispatch(getSession),
    onChangeTab: index => dispatch(changeTab(index)),
    onChangeAccordion: index => dispatch(changeAccordion(index)),
    fetchInitialPage: key => dispatch(fetchInitialPage(key)),
    fetchNextPage: key => dispatch(fetchNextPage(key)),
    toggleFolder: id => dispatch(toggleFolder(id)),
    fetchFolders: () => dispatch(fetchFolders()),
    fetchInitialImages: (opts = {category: DEFAULT_FILE_CATEGORY}) =>
      dispatch(fetchInitialImages(opts)),
    fetchNextImages: (opts = {category: DEFAULT_FILE_CATEGORY}) => dispatch(fetchNextImages(opts)),
    startUpload: (tabContext, fileMetaProps) =>
      dispatch(uploadPreflight(tabContext, fileMetaProps)),
    flickrSearch: term => dispatch(searchFlickr(term)),
    toggleFlickrForm: () => dispatch(openOrCloseFlickrForm()),
    toggleUploadForm: () => dispatch(openOrCloseUploadForm()),
    toggleNewPageForm: () => dispatch(openOrCloseNewPageForm()),
    startIconMakerUpload: (fileMetaProps, uploadSettings) =>
      dispatch(uploadToIconMakerFolder(fileMetaProps, uploadSettings)),
    startMediaUpload: (tabContext, fileMetaProps) =>
      dispatch(uploadToMediaFolder(tabContext, fileMetaProps)),
    createMediaServerSession: () => dispatch(createMediaServerSession()),
    // saveMediaRecording: (file, editor, dismiss) => dispatch(saveMediaRecording(file, editor, dismiss)),
    mediaUploadComplete: (error, uploadData) => dispatch(mediaUploadComplete(error, uploadData)),
    fetchInitialDocs: () => dispatch(fetchInitialDocs()),
    fetchNextDocs: () => dispatch(fetchNextDocs()),
    fetchInitialMedia: () => dispatch(fetchInitialMedia()),
    fetchNextMedia: () => dispatch(fetchNextMedia()),
    updateMediaObject: new_values => dispatch(updateMediaObject(new_values)),
    onChangeContext: newContext => dispatch(changeContext(newContext)),
    onChangeSearchString: searchString => dispatch(changeSearchString(searchString)),
    onChangeSortBy: sortBy => dispatch(changeSortBy(sortBy)),
    onAllFilesLoading: isLoading => dispatch(allFilesLoading(isLoading)),
  }
}
