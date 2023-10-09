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

import 'isomorphic-fetch'
import {parse} from 'url'
import {
  saveClosedCaptions,
  saveClosedCaptionsForAttachment,
  CONSTANTS,
} from '@instructure/canvas-media'
import {downloadToWrap, fixupFileUrl} from '../common/fileUrl'
import alertHandler from '../rce/alertHandler'
import buildError from './buildError'
import RCEGlobals from '../rce/RCEGlobals'

export function headerFor(jwt) {
  return {Authorization: 'Bearer ' + jwt}
}
export function originFromHost(host, windowOverride) {
  let origin = host

  if (typeof origin !== 'string') {
    origin = ''
  } else if (origin && origin.substr(0, 4) !== 'http') {
    origin = `//${origin}`
    const windowHandle = windowOverride || (typeof window !== 'undefined' ? window : undefined)
    if (origin.length > 0 && windowHandle?.location?.protocol) {
      origin = `${windowHandle.location.protocol}${origin}`
    }
  }
  return origin
}

// filter a response to raise an error on a 400+ status
function checkStatus(response) {
  if (response.status < 400) {
    return response
  } else {
    const error = new Error(response.statusText)
    error.response = response
    throw error
  }
}

function defaultRefreshTokenHandler() {
  throw new Error('Token expired, no refresh function provided')
}

function normalizeFileData(file) {
  return {
    // copy the name to the default display name if none provided
    display_name: file.name,
    ...file,
    // wrap the url
    href: downloadToWrap(file.href || file.url),
  }
}

function throwConnectionError(error) {
  if (error.name === 'TypeError') {
    // eslint-disable-next-line no-console
    console.error(`Failed to fetch from the canvas-rce-api.
      Did you forget to start it or configure it?
      Details can be found at https://github.com/instructure/canvas-rce-api
    `)
  }
  throw error
}

class RceApiSource {
  constructor(options = {}) {
    this.jwt = options.jwt
    this.host = options.host
    this.refreshToken = options.refreshToken || defaultRefreshTokenHandler
    this.hasSession = false
    this.alertFunc = options.alertFunc || alertHandler.handleAlert
    this.canvasOrigin = options.canvasOrigin || window.origin
  }

  getSession() {
    const headers = headerFor(this.jwt)
    const uri = this.baseUri('session')
    return this.apiReallyFetch(uri, headers)
      .then(data => {
        this.hasSession = true
        return data
      })
      .catch(throwConnectionError)
  }

  // initial state of a collection is empty, not loading, with bookmark set to
  // uri for initial page fetch
  initializeCollection(endpoint, props) {
    return {
      links: [],
      bookmark: this.uriFor(endpoint, props),
      isLoading: false,
      hasMore: true,
      searchString: props.searchString,
    }
  }

  initializeUpload() {
    return {
      uploading: false,
      folders: {},
      formExpanded: false,
    }
  }

  initializeImages(props) {
    return this.initializeDocuments(props)
  }

  initializeDocuments(props) {
    return {
      [props.contextType]: {
        files: [],
        bookmark: null,
        isLoading: false,
        hasMore: true,
      },
      searchString: '',
    }
  }

  initializeMedia(props) {
    return this.initializeDocuments(props)
  }

  initializeFlickr() {
    return {
      searchResults: [],
      searching: false,
      formExpanded: false,
    }
  }

  // fetches the given URI and filters it to either an error or parsed response
  fetchPage(uri) {
    return this.apiFetch(uri, headerFor(this.jwt))
  }

  fetchBookmarkedData(fetchFunction, properties, onSuccess, onError, bookmark) {
    return fetchFunction(properties, bookmark)
      .then(result => {
        onSuccess(result)
        if (result.bookmark) {
          this.fetchBookmarkedData(fetchFunction, properties, onSuccess, onError, result.bookmark)
        }
      })
      .catch(error => {
        onError(error)
      })
  }

  fetchDocs(props) {
    const documents = props.documents[props.contextType]
    const uri = documents.bookmark || this.uriFor('documents', props)
    return this.apiFetch(uri, headerFor(this.jwt)).then(({bookmark, files}) => {
      return {
        bookmark,
        files: files.map(f =>
          fixupFileUrl(props.contextType, props.contextId, f, this.canvasOrigin)
        ),
      }
    })
  }

  fetchMedia(props) {
    const media = props.media[props.contextType]
    const uri = media.bookmark || this.uriFor('media', props)

    if (RCEGlobals.getFeatures()?.media_links_use_attachment_id) {
      return this.apiFetch(uri, headerFor(this.jwt)).then(({bookmark, files}) => {
        return {
          bookmark,
          files: files.map(f =>
            fixupFileUrl(props.contextType, props.contextId, f, this.canvasOrigin)
          ),
        }
      })
    }

    return this.apiFetch(uri, headerFor(this.jwt))
  }

  fetchFiles(uri) {
    return this.fetchPage(uri).then(({bookmark, files}) => {
      return {
        bookmark,
        files: files.map(normalizeFileData),
      }
    })
  }

  fetchLinks(key, props) {
    const {collections} = props
    const bookmark = collections[key].bookmark || this.uriFor(key, props)
    return this.fetchPage(bookmark)
  }

  fetchRootFolder(props) {
    return this.fetchPage(this.uriFor('folders', props), this.jwt)
  }

  mediaServerSession() {
    return this.apiPost(this.baseUri('v1/services/kaltura_session'), headerFor(this.jwt), {})
  }

  uploadMediaToCanvas(mediaObject) {
    const body = {
      id: mediaObject.entryId,
      type:
        {2: 'image', 5: 'audio'}[mediaObject.mediaType] || mediaObject.type.includes('audio')
          ? 'audio'
          : 'video',
      context_code: mediaObject.contextCode,
      title: mediaObject.title,
      user_entered_title: mediaObject.userTitle,
    }

    return this.apiPost(this.baseUri('media_objects'), headerFor(this.jwt), body)
  }

  updateMediaObject(apiProps, {media_object_id, title, attachment_id}) {
    const uri =
      RCEGlobals.getFeatures()?.media_links_use_attachment_id && attachment_id
        ? `${this.baseUri(
            'media_attachments',
            apiProps.host
          )}/${attachment_id}?user_entered_title=${encodeURIComponent(title)}`
        : `${this.baseUri(
            'media_objects',
            apiProps.host
          )}/${media_object_id}?user_entered_title=${encodeURIComponent(title)}`
    return this.apiPost(uri, headerFor(this.jwt), null, 'PUT')
  }

  // PUT to //RCS/api/media_objects/:mediaId/media_tracks [{locale, content}, ...]
  // receive back a 200 with the new subtitles, or a 4xx error
  updateClosedCaptions(
    apiProps,
    {media_object_id, attachment_id, subtitles},
    maxBytes = CONSTANTS.CC_FILE_MAX_BYTES
  ) {
    const rcsConfig = {
      origin: originFromHost(apiProps.host),
      headers: headerFor(apiProps.jwt),
    }
    const saveCaptions = attachment_id
      ? saveClosedCaptionsForAttachment(attachment_id, subtitles, rcsConfig, maxBytes)
      : saveClosedCaptions(media_object_id, subtitles, rcsConfig, maxBytes)

    return saveCaptions.catch(e => {
      this.alertFunc(buildError({message: 'failed to save captions'}, e))
    })
  }

  // GET /media_objects/:mediaId/media_tracks
  // receive back the current list of media_tracks
  fetchClosedCaptions(_mediaId) {
    return Promise.resolve([
      {locale: 'af', content: '1\r\n00:00:00,000 --> 00:00:01,251\r\nThis is the content\r\n'},
      {locale: 'es', content: '1\r\n00:00:00,000 --> 00:00:01,251\r\nThis is the content\r\n'},
    ])
  }

  // fetches folders for the given context to upload files to
  fetchFolders(props, bookmark) {
    const headers = headerFor(this.jwt)
    const uri = bookmark || this.uriFor('folders/all', props)
    return this.apiFetch(uri, headers)
  }

  // Fetches all files for a given folder
  fetchFilesForFolder(props, bookmark) {
    let uri

    if (!bookmark) {
      const perPageQuery = props.perPage ? `per_page=${props.perPage}` : ''
      const searchParam = getSearchParam(props.searchString)

      uri = `${props.filesUrl}`
      uri += perPageQuery ? `?${perPageQuery}` : ''
      if (searchParam) {
        uri += perPageQuery ? `${searchParam}` : `?${searchParam}`
      }

      if (props.sortBy) {
        uri += `${getSortParams(props.sortBy.sort, props.sortBy.order)}`
      }
    }

    return this.fetchPage(uri || bookmark, this.jwt)
  }

  fetchSubFolders(props, bookmark) {
    const uri = bookmark || `${this.baseUri('folders', props.host)}/${props.folderId}`
    return this.apiFetch(uri, headerFor(this.jwt))
  }

  fetchIconMakerFolder({contextId, contextType}) {
    const uri = this.uriFor('folders/icon_maker', {
      contextId,
      contextType,
      host: this.host,
      jwt: this.jwt,
    })
    return this.fetchPage(uri)
  }

  fetchMediaFolder(props) {
    let uri
    if (props.contextType === 'user') {
      uri = this.uriFor('folders', props)
    } else {
      uri = this.uriFor('folders/media', props)
    }
    return this.fetchPage(uri)
  }

  fetchMediaObjectIframe(mediaObjectId) {
    return this.fetchPage(this.uriFor(`media_objects_iframe/${mediaObjectId}`))
  }

  fetchImages(props) {
    const images = props.images[props.contextType]
    const uri = images.bookmark || this.uriFor('images', props)

    const headers = headerFor(this.jwt)
    return this.apiFetch(uri, headers).then(({bookmark, files}) => {
      return {
        bookmark,
        files: files.map(f =>
          fixupFileUrl(props.contextType, props.contextId, f, this.canvasOrigin)
        ),
        searchString: props.searchString,
      }
    })
  }

  preflightUpload(fileProps, apiProps) {
    const headers = headerFor(this.jwt)
    const uri = this.baseUri('upload', apiProps.host)
    const body = {
      contextId: apiProps.contextId,
      contextType: apiProps.contextType,
      file: fileProps,
      no_redirect: true,
      onDuplicate: apiProps.onDuplicate,
      category: apiProps.category,
    }

    return this.apiPost(uri, headers, body)
  }

  uploadFRD(fileDomObject, preflightProps) {
    const data = new window.FormData()
    Object.keys(preflightProps.upload_params).forEach(uploadProp => {
      data.append(uploadProp, preflightProps.upload_params[uploadProp])
    })
    data.append('file', fileDomObject)
    const fetchOptions = {method: 'POST', body: data}

    if (
      !preflightProps.upload_params['x-amz-signature'] &&
      !preflightProps.upload_url.includes('files_api')
    ) {
      // _not_ an S3 upload, include the credentials in the upload POST
      // local uploads can include crendentials for same-origin requests
      fetchOptions.credentials = 'include'
    }
    return fetch(preflightProps.upload_url, fetchOptions)
      .then(checkStatus)
      .then(res => res.json())
      .then(uploadResults => {
        return this.finalizeUpload(preflightProps, uploadResults)
      })
      .catch(e => {
        this.alertFunc(buildError({}, e))
      })
  }

  finalizeUpload(preflightProps, uploadResults) {
    if (preflightProps.upload_params.success_url) {
      // s3 upload, follow-up at success_url to finalize. the success_url doesn't
      // require authentication
      return fetch(preflightProps.upload_params.success_url)
        .then(checkStatus)
        .then(res => res.json())
    } else if (uploadResults.location) {
      // inst-fs upload, follow-up by fetching file identified by location in
      // response. we can't just fetch the location as would be intended because
      // it requires Canvas authentication. we also don't have an RCE API
      // endpoint to forward it through.
      const {pathname} = parse(uploadResults.location)
      const matchData = pathname.match(/^\/api\/v1\/files\/((?:\d+~)?\d+)$/)
      if (!matchData) {
        const error = new Error('cannot determine file ID from location')
        error.location = uploadResults.location
        throw error
      }
      const fileId = matchData[1]
      return this.getFile(fileId).then(fileResults => {
        fileResults.uuid = uploadResults.uuid // if present, we'll need the uuid for the file verifier downstream
        return fileResults
      })
    } else {
      // local-storage upload, this _is_ the attachment information
      return Promise.resolve(uploadResults)
    }
  }

  setUsageRights(fileId, usageRights) {
    const headers = headerFor(this.jwt)
    const uri = this.baseUri('usage_rights')
    const body = {fileId, ...usageRights}
    return this.apiPost(uri, headers, body)
  }

  searchFlickr(term, apiProps) {
    const headers = headerFor(this.jwt)
    const base = this.baseUri('flickr_search', apiProps.host)
    const uri = `${base}?term=${encodeURIComponent(term)}`
    return this.apiFetch(uri, headers)
  }

  getFile(id, options = {}) {
    const headers = headerFor(this.jwt)
    const base = this.baseUri('file')

    // Valid query parameters for getFile
    const {replacement_chain_context_type, replacement_chain_context_id, include} = options

    const uri = this.addParamsIfPresent(`${base}/${id}`, {
      replacement_chain_context_type,
      replacement_chain_context_id,
      include,
    })

    return this.apiFetch(uri, headers).then(normalizeFileData)
  }

  // @private
  addParamsIfPresent(uri, params) {
    let url

    try {
      url = new URL(uri)
    } catch (e) {
      // Just return the URI if it was invalid
      return uri
    }

    // Add all truthy parameters to the URL
    for (const [name, value] of Object.entries(params)) {
      if (!value) continue

      url.searchParams.append(name, value)
    }

    return url.toString()
  }

  // @private
  async apiFetch(uri, headers, options) {
    if (!this.hasSession) {
      await this.getSession()
    }

    return this.apiReallyFetch(uri, headers, options)
  }

  apiReallyFetch(uri, headers, options = {}) {
    uri = this.normalizeUriProtocol(uri)

    return fetch(uri, {headers})
      .then(response => {
        if (response.status === 401) {
          // retry once with fresh token
          return this.buildRetryHeaders(headers).then(newHeaders => {
            return fetch(uri, {headers: newHeaders})
          })
        } else {
          return response
        }
      })
      .then(checkStatus)
      .then(options.skipParse ? () => {} : res => res.json())
      .catch(throwConnectionError)
      .catch(e => {
        this.alertFunc(buildError(e))
        throw e
      })
  }

  // @private
  apiPost(uri, headers, body, method = 'POST') {
    headers = {...headers, 'Content-Type': 'application/json'}
    const fetchOptions = {
      method,
      headers,
    }
    if (body) {
      fetchOptions.body = JSON.stringify(body)
    } else {
      fetchOptions.form = body
    }
    uri = this.normalizeUriProtocol(uri)
    return fetch(uri, fetchOptions)
      .then(response => {
        if (response.status === 401) {
          // retry once with fresh token
          return this.buildRetryHeaders(fetchOptions.headers).then(newHeaders => {
            const newOptions = {...fetchOptions, headers: newHeaders}
            return fetch(uri, newOptions)
          })
        } else {
          return response
        }
      })
      .then(checkStatus)
      .then(res => res.json())
      .catch(throwConnectionError)
      .catch(e =>
        e.response.json().then(responseBody => {
          console.error(e) // eslint-disable-line no-console
          this.alertFunc(buildError(responseBody))
          throw e
        })
      )
  }

  // @private
  normalizeUriProtocol(uri, windowOverride) {
    const windowHandle = windowOverride || (typeof window !== 'undefined' ? window : undefined)
    if (windowHandle && windowHandle.location && windowHandle.location.protocol === 'https:') {
      return uri.replace('http://', 'https://')
    }
    return uri
  }

  // @private
  buildRetryHeaders(headers) {
    return new Promise(resolve => {
      this.refreshToken(freshToken => {
        this.jwt = freshToken
        const freshHeader = headerFor(freshToken)
        const mergedHeaders = {...headers, ...freshHeader}
        resolve(mergedHeaders)
      })
    })
  }

  baseUri(endpoint, host, windowOverride) {
    if (!host && this.host) {
      host = this.host
    }
    host = originFromHost(host, windowOverride)

    const sharedEndpoints = ['images', 'media', 'documents', 'all'] // 'all' will eventually be something different
    const endpt = sharedEndpoints.includes(endpoint) ? 'documents' : endpoint
    return `${host}/api/${endpt}`
  }

  // returns the URI to use with the fetchPage method to fetch the first page of
  // the given endpoint. e.g. for wikiPages it might return:
  //
  //   //rce.docker/api/wikiPages?context_type=course&context_id=42
  //
  uriFor(endpoint, props) {
    const {host, contextType, contextId, sortBy, searchString, perPage} = props
    let extra = ''
    const pageSizeParam = perPage ? `&per_page=${perPage}` : ''

    switch (endpoint) {
      case 'images':
        extra = `&content_types=image${getSortParams(sortBy.sort, sortBy.dir)}${getSearchParam(
          searchString
        )}${optionalQuery(props, 'category')}`
        break
      case 'media': // when requesting media files via the documents endpoint
        extra = `&content_types=video,audio${getSortParams(
          sortBy.sort,
          sortBy.dir
        )}${getSearchParam(searchString)}`
        break
      case 'documents':
        extra = `&exclude_content_types=image,video,audio${getSortParams(
          sortBy.sort,
          sortBy.dir
        )}${getSearchParam(searchString)}`
        break
      case 'media_objects': // when requesting media objects (this is the currently used branch)
        extra = `${getSortParams(
          sortBy.sort === 'alphabetical' ? 'title' : 'date',
          sortBy.dir
        )}${getSearchParam(searchString)}`
        break
      default:
        extra = getSearchParam(searchString)
    }

    return `${this.baseUri(
      endpoint,
      host
    )}?contextType=${contextType}&contextId=${contextId}${pageSizeParam}${extra}`
  }
}

function getSortParams(sort, dir) {
  let sortBy = sort
  if (sortBy === 'date_added') {
    sortBy = 'created_at'
  } else if (sortBy === 'alphabetical') {
    sortBy = 'name'
  }
  return `&sort=${sortBy}&order=${dir}`
}

function optionalQuery(props, name) {
  return props[name] ? `&${name}=${props[name]}` : ''
}

export function getSearchParam(searchString) {
  return searchString?.length >= 3 ? `&search_term=${encodeURIComponent(searchString)}` : ''
}

export default RceApiSource
