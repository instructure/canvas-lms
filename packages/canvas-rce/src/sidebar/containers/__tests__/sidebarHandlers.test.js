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

import propsFromDispatch from '../sidebarHandlers'
import * as actions from '../../actions/ui'
import * as dataActions from '../../actions/data'
import * as imageActions from '../../actions/images'
import * as uploadActions from '../../actions/upload'
import * as flickrActions from '../../actions/flickr'
import * as fileActions from '../../actions/files'
import * as linkActions from '../../actions/links'
import * as docActions from '../../actions/documents'
import * as mediaActions from '../../actions/media'
import * as filterActions from '../../actions/filter'
import * as allFilesActions from '../../actions/all_files'
import * as sessionActions from '../../actions/session'

jest.mock('../../actions/ui')
jest.mock('../../actions/data')
jest.mock('../../actions/images')
jest.mock('../../actions/upload')
jest.mock('../../actions/flickr')
jest.mock('../../actions/files')
jest.mock('../../actions/links')
jest.mock('../../actions/documents')
jest.mock('../../actions/media')
jest.mock('../../actions/filter')
jest.mock('../../actions/all_files')
jest.mock('../../actions/session')

describe('Sidebar handlers', () => {
  let dispatch
  let props

  beforeEach(() => {
    dispatch = jest.fn()
    props = propsFromDispatch(dispatch)
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('loadSession', () => {
    it('dispatches getSession action', () => {
      props.loadSession()
      expect(dispatch).toHaveBeenCalledWith(sessionActions.get)
    })
  })

  describe('tab and accordion handlers', () => {
    it('dispatches changeTab action with index', () => {
      const index = 2
      actions.changeTab.mockReturnValue('CHANGE_TAB_ACTION')
      props.onChangeTab(index)
      expect(actions.changeTab).toHaveBeenCalledWith(index)
      expect(dispatch).toHaveBeenCalledWith('CHANGE_TAB_ACTION')
    })

    it('dispatches changeAccordion action with index', () => {
      const index = 1
      actions.changeAccordion.mockReturnValue('CHANGE_ACCORDION_ACTION')
      props.onChangeAccordion(index)
      expect(actions.changeAccordion).toHaveBeenCalledWith(index)
      expect(dispatch).toHaveBeenCalledWith('CHANGE_ACCORDION_ACTION')
    })
  })

  describe('page fetching', () => {
    it('dispatches fetchInitialPage action with key', () => {
      const key = 'test_key'
      dataActions.fetchInitialPage.mockReturnValue('FETCH_INITIAL_PAGE_ACTION')
      props.fetchInitialPage(key)
      expect(dataActions.fetchInitialPage).toHaveBeenCalledWith(key)
      expect(dispatch).toHaveBeenCalledWith('FETCH_INITIAL_PAGE_ACTION')
    })

    it('dispatches fetchNextPage action with key', () => {
      const key = 'test_key'
      dataActions.fetchNextPage.mockReturnValue('FETCH_NEXT_PAGE_ACTION')
      props.fetchNextPage(key)
      expect(dataActions.fetchNextPage).toHaveBeenCalledWith(key)
      expect(dispatch).toHaveBeenCalledWith('FETCH_NEXT_PAGE_ACTION')
    })
  })

  describe('folder management', () => {
    it('dispatches toggleFolder action with id', () => {
      const id = 'folder_1'
      fileActions.toggle.mockReturnValue('TOGGLE_FOLDER_ACTION')
      props.toggleFolder(id)
      expect(fileActions.toggle).toHaveBeenCalledWith(id)
      expect(dispatch).toHaveBeenCalledWith('TOGGLE_FOLDER_ACTION')
    })

    it('dispatches fetchFolders action', () => {
      uploadActions.fetchFolders.mockReturnValue('FETCH_FOLDERS_ACTION')
      props.fetchFolders()
      expect(dispatch).toHaveBeenCalledWith('FETCH_FOLDERS_ACTION')
    })
  })

  describe('image management', () => {
    it('dispatches fetchInitialImages with default category', () => {
      imageActions.fetchInitialImages.mockReturnValue('FETCH_INITIAL_IMAGES_ACTION')
      props.fetchInitialImages()
      expect(imageActions.fetchInitialImages).toHaveBeenCalledWith({category: 'uncategorized'})
      expect(dispatch).toHaveBeenCalledWith('FETCH_INITIAL_IMAGES_ACTION')
    })

    it('dispatches fetchNextImages with default category', () => {
      imageActions.fetchNextImages.mockReturnValue('FETCH_NEXT_IMAGES_ACTION')
      props.fetchNextImages()
      expect(imageActions.fetchNextImages).toHaveBeenCalledWith({category: 'uncategorized'})
      expect(dispatch).toHaveBeenCalledWith('FETCH_NEXT_IMAGES_ACTION')
    })
  })

  describe('upload management', () => {
    it('dispatches uploadPreflight action', () => {
      const context = 'course'
      const fileProps = {name: 'test.jpg'}
      uploadActions.uploadPreflight.mockReturnValue('UPLOAD_PREFLIGHT_ACTION')
      props.startUpload(context, fileProps)
      expect(uploadActions.uploadPreflight).toHaveBeenCalledWith(context, fileProps)
      expect(dispatch).toHaveBeenCalledWith('UPLOAD_PREFLIGHT_ACTION')
    })

    it('dispatches openOrCloseUploadForm action', () => {
      uploadActions.openOrCloseUploadForm.mockReturnValue('TOGGLE_UPLOAD_FORM_ACTION')
      props.toggleUploadForm()
      expect(dispatch).toHaveBeenCalledWith('TOGGLE_UPLOAD_FORM_ACTION')
    })

    it('dispatches uploadToIconMakerFolder action', () => {
      const fileProps = {name: 'icon.svg'}
      const settings = {width: 100, height: 100}
      uploadActions.uploadToIconMakerFolder.mockReturnValue('UPLOAD_ICON_ACTION')
      props.startIconMakerUpload(fileProps, settings)
      expect(uploadActions.uploadToIconMakerFolder).toHaveBeenCalledWith(fileProps, settings)
      expect(dispatch).toHaveBeenCalledWith('UPLOAD_ICON_ACTION')
    })

    it('dispatches uploadToMediaFolder action', () => {
      const context = 'course'
      const fileProps = {name: 'video.mp4'}
      uploadActions.uploadToMediaFolder.mockReturnValue('UPLOAD_MEDIA_ACTION')
      props.startMediaUpload(context, fileProps)
      expect(uploadActions.uploadToMediaFolder).toHaveBeenCalledWith(context, fileProps)
      expect(dispatch).toHaveBeenCalledWith('UPLOAD_MEDIA_ACTION')
    })

    it('dispatches createMediaServerSession action', () => {
      uploadActions.createMediaServerSession.mockReturnValue('CREATE_MEDIA_SESSION_ACTION')
      props.createMediaServerSession()
      expect(dispatch).toHaveBeenCalledWith('CREATE_MEDIA_SESSION_ACTION')
    })

    it('dispatches mediaUploadComplete action', () => {
      const error = null
      const uploadData = {id: '123', name: 'video.mp4'}
      uploadActions.mediaUploadComplete.mockReturnValue('MEDIA_UPLOAD_COMPLETE_ACTION')
      props.mediaUploadComplete(error, uploadData)
      expect(uploadActions.mediaUploadComplete).toHaveBeenCalledWith(error, uploadData)
      expect(dispatch).toHaveBeenCalledWith('MEDIA_UPLOAD_COMPLETE_ACTION')
    })
  })

  describe('flickr management', () => {
    it('dispatches searchFlickr action with term', () => {
      const term = 'test'
      flickrActions.searchFlickr.mockReturnValue('SEARCH_FLICKR_ACTION')
      props.flickrSearch(term)
      expect(flickrActions.searchFlickr).toHaveBeenCalledWith(term)
      expect(dispatch).toHaveBeenCalledWith('SEARCH_FLICKR_ACTION')
    })

    it('dispatches openOrCloseFlickrForm action', () => {
      flickrActions.openOrCloseFlickrForm.mockReturnValue('TOGGLE_FLICKR_FORM_ACTION')
      props.toggleFlickrForm()
      expect(dispatch).toHaveBeenCalledWith('TOGGLE_FLICKR_FORM_ACTION')
    })
  })

  describe('links management', () => {
    it('dispatches openOrCloseNewPageForm action', () => {
      linkActions.openOrCloseNewPageForm.mockReturnValue('TOGGLE_NEW_PAGE_FORM_ACTION')
      props.toggleNewPageForm()
      expect(dispatch).toHaveBeenCalledWith('TOGGLE_NEW_PAGE_FORM_ACTION')
    })
  })

  describe('documents management', () => {
    it('dispatches fetchInitialDocs action', () => {
      docActions.fetchInitialDocs.mockReturnValue('FETCH_INITIAL_DOCS_ACTION')
      props.fetchInitialDocs()
      expect(dispatch).toHaveBeenCalledWith('FETCH_INITIAL_DOCS_ACTION')
    })

    it('dispatches fetchNextDocs action', () => {
      docActions.fetchNextDocs.mockReturnValue('FETCH_NEXT_DOCS_ACTION')
      props.fetchNextDocs()
      expect(dispatch).toHaveBeenCalledWith('FETCH_NEXT_DOCS_ACTION')
    })
  })

  describe('media management', () => {
    it('dispatches fetchInitialMedia action', () => {
      mediaActions.fetchInitialMedia.mockReturnValue('FETCH_INITIAL_MEDIA_ACTION')
      props.fetchInitialMedia()
      expect(dispatch).toHaveBeenCalledWith('FETCH_INITIAL_MEDIA_ACTION')
    })

    it('dispatches fetchNextMedia action', () => {
      mediaActions.fetchNextMedia.mockReturnValue('FETCH_NEXT_MEDIA_ACTION')
      props.fetchNextMedia()
      expect(dispatch).toHaveBeenCalledWith('FETCH_NEXT_MEDIA_ACTION')
    })

    it('dispatches updateMediaObject action', () => {
      const newValues = {title: 'New Title', description: 'New Description'}
      mediaActions.updateMediaObject.mockReturnValue('UPDATE_MEDIA_OBJECT_ACTION')
      props.updateMediaObject(newValues)
      expect(mediaActions.updateMediaObject).toHaveBeenCalledWith(newValues)
      expect(dispatch).toHaveBeenCalledWith('UPDATE_MEDIA_OBJECT_ACTION')
    })
  })

  describe('filter management', () => {
    it('dispatches changeContext action', () => {
      const context = {contextType: 'course', contextId: '1'}
      filterActions.changeContext.mockReturnValue('CHANGE_CONTEXT_ACTION')
      props.onChangeContext(context)
      expect(filterActions.changeContext).toHaveBeenCalledWith(context)
      expect(dispatch).toHaveBeenCalledWith('CHANGE_CONTEXT_ACTION')
    })

    it('dispatches changeSearchString action', () => {
      const searchString = 'test'
      filterActions.changeSearchString.mockReturnValue('CHANGE_SEARCH_STRING_ACTION')
      props.onChangeSearchString(searchString)
      expect(filterActions.changeSearchString).toHaveBeenCalledWith(searchString)
      expect(dispatch).toHaveBeenCalledWith('CHANGE_SEARCH_STRING_ACTION')
    })

    it('dispatches changeSortBy action', () => {
      const sortBy = 'date'
      filterActions.changeSortBy.mockReturnValue('CHANGE_SORT_BY_ACTION')
      props.onChangeSortBy(sortBy)
      expect(filterActions.changeSortBy).toHaveBeenCalledWith(sortBy)
      expect(dispatch).toHaveBeenCalledWith('CHANGE_SORT_BY_ACTION')
    })
  })

  describe('all files management', () => {
    it('dispatches allFilesLoading action', () => {
      const isLoading = true
      allFilesActions.allFilesLoading.mockReturnValue('ALL_FILES_LOADING_ACTION')
      props.onAllFilesLoading(isLoading)
      expect(allFilesActions.allFilesLoading).toHaveBeenCalledWith(isLoading)
      expect(dispatch).toHaveBeenCalledWith('ALL_FILES_LOADING_ACTION')
    })
  })
})
