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
import {downloadToWrap} from '../../common/fileUrl'
import formatMessage from '../../format-message'
import alertHandler from '../../rce/alertHandler'

function headerFor(jwt) {
  return {Authorization: 'Bearer ' + jwt}
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

// convert a successful response into the parsed out data
function parseResponse(response) {
  // NOTE: this returns a promise, not a synchronous result. since it's passed
  // to a .then(), that's fine, but before reusing somewhere where intended to
  // be synchronous, be aware of that
  return response.text().then(text => {
    let json = text
    try {
      json = text.replace(/^while\(1\);/, '')
    } catch (err) {
      // eslint-disable-next-line no-console
      console.warn('Strange json package', err)
    }
    return JSON.parse(json)
  })
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
    url: downloadToWrap(file.url)
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
  }

  getSession() {
    const headers = headerFor(this.jwt)
    const uri = this.baseUri('session')
    return this.apiReallyFetch(uri, headers)
      .then(() => {
        this.hasSession = true
      })
      .catch(throwConnectionError)
  }

  // initial state of a collection is empty, not loading, with bookmark set to
  // uri for initial page fetch
  initializeCollection(endpoint, props) {
    return {
      links: [],
      bookmark: this.uriFor(endpoint, props),
      loading: false
    }
  }

  initializeUpload() {
    return {
      uploading: false,
      folders: {},
      formExpanded: false
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
        hasMore: true
      }
    }
  }

  initializeMedia(props) {
    return this.initializeDocuments(props)
  }

  initializeFlickr() {
    return {
      searchResults: [],
      searching: false,
      formExpanded: false
    }
  }

  // fetches the given URI and filters it to either an error or parsed response
  fetchPage(uri) {
    return this.apiFetch(uri, headerFor(this.jwt))
  }

  fetchDocs(props) {
    const documents = props.documents[props.contextType]
    const uri = documents.bookmark || this.uriFor('documents', props)
    return this.apiFetch(uri, headerFor(this.jwt))
  }

  fetchMedia(props) {
    const media = props.media[props.contextType]
    const uri = media.bookmark || this.uriFor('media_objects', props)
    return this.apiFetch(uri, headerFor(this.jwt))
  }

  fetchFiles(uri) {
    return this.fetchPage(uri).then(({bookmark, files}) => {
      return {
        bookmark,
        files: files.map(normalizeFileData)
      }
    })
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
      user_entered_title: mediaObject.userTitle
    }

    return this.apiPost(this.baseUri('media_objects'), headerFor(this.jwt), body)
  }

  updateMediaObject(props, {media_object_id, title}) {
    const uri = `${this.baseUri(
      'media_objects',
      props.host
    )}/${media_object_id}?user_entered_title=${encodeURIComponent(title)}`
    return this.apiPost(uri, headerFor(this.jwt), null, 'PUT')
  }

  // fetches folders for the given context to upload files to
  fetchFolders(props, bookmark) {
    const headers = headerFor(this.jwt)
    const uri = bookmark || this.uriFor('folders/all', props)
    return this.apiFetch(uri, headers)
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
    return this.apiFetch(uri, headers)
  }

  preflightUpload(fileProps, apiProps) {
    const headers = headerFor(this.jwt)
    const uri = this.baseUri('upload', apiProps.host)
    const body = {
      contextId: apiProps.contextId,
      contextType: apiProps.contextType,
      file: fileProps,
      no_redirect: true
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
    if (!preflightProps.upload_params['x-amz-signature']) {
      // _not_ an S3 upload, include the credentials in the upload POST
      fetchOptions.credentials = 'include'
    }
    return fetch(preflightProps.upload_url, fetchOptions)
      .then(checkStatus)
      .then(parseResponse)
      .then(uploadResults => {
        return this.finalizeUpload(preflightProps, uploadResults)
      })
      .then(normalizeFileData)
      .catch(_e => {
        this.alertFunc({
          text: formatMessage(
            'Something went wrong uploading, check your connection and try again.'
          ),
          variant: 'error'
        })

        // console.error(e) // eslint-disable-line no-console
      })
  }

  finalizeUpload(preflightProps, uploadResults) {
    if (preflightProps.upload_params.success_url) {
      // s3 upload, follow-up at success_url to finalize. the success_url doesn't
      // require authentication
      return fetch(preflightProps.upload_params.success_url)
        .then(checkStatus)
        .then(parseResponse)
    } else if (uploadResults.location) {
      // inst-fs upload, follow-up by fetching file identified by location in
      // response. we can't just fetch the location as would be intended because
      // it requires Canvas authentication. we also don't have an RCE API
      // endpoint to forward it through.
      const {pathname} = parse(uploadResults.location)
      const matchData = pathname.match(/^\/api\/v1\/files\/(\d+)$/)
      if (!matchData) {
        const error = new Error('cannot determine file ID from location')
        error.location = uploadResults.location
        throw error
      }
      const fileId = matchData[1]
      return this.getFile(fileId)
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

  searchUnsplash(term, page) {
    const headers = headerFor(this.jwt)
    const base = this.baseUri('unsplash/search')
    const uri = `${base}?term=${encodeURIComponent(term)}&page=${page}&per_page=12`
    return this.apiFetch(uri, headers)
  }

  pingbackUnsplash(id) {
    const headers = headerFor(this.jwt)
    const base = this.baseUri('unsplash/pingback')
    const uri = `${base}?id=${id}`
    return this.apiFetch(uri, headers, {skipParse: true})
  }

  getFile(id) {
    const headers = headerFor(this.jwt)
    const base = this.baseUri('file')
    const uri = `${base}/${id}`
    return this.apiFetch(uri, headers).then(normalizeFileData)
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
        if (response.status == 401) {
          // retry once with fresh token
          return this.buildRetryHeaders(headers).then(newHeaders => {
            return fetch(uri, {headers: newHeaders})
          })
        } else {
          return response
        }
      })
      .then(checkStatus)
      .then(options.skipParse ? () => {} : parseResponse)
      .catch(throwConnectionError)
      .catch(e => {
        this.alertFunc({
          text: formatMessage('Something went wrong, try again after refreshing the page'),
          variant: 'error'
        })
        throw e
      })
  }

  // @private
  apiPost(uri, headers, body, method = 'POST') {
    headers = {...headers, 'Content-Type': 'application/json'}
    const fetchOptions = {
      method,
      headers,
      body: body ? JSON.stringify(body) : undefined
    }
    uri = this.normalizeUriProtocol(uri)
    return fetch(uri, fetchOptions)
      .then(response => {
        if (response.status == 401) {
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
      .then(parseResponse)
      .catch(throwConnectionError)
      .catch(e => {
        this.alertFunc({
          text: formatMessage(
            'Something went wrong uploading, check your connection and try again.'
          ),
          variant: 'error'
        })
        throw e
        // console.error(e) // eslint-disable-line no-console
      })
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
    if (typeof host !== 'string') {
      host = ''
    } else if (host && host.substr(0, 4) !== 'http') {
      host = `//${host}`
      const windowHandle = windowOverride || (typeof window !== 'undefined' ? window : undefined)
      if (
        host.length > 0 &&
        windowHandle &&
        windowHandle.location &&
        windowHandle.location.protocol
      ) {
        host = `${windowHandle.location.protocol}${host}`
      }
    }
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
    const {host, contextType, contextId} = props
    let extra = ''
    switch (endpoint) {
      case 'images':
        extra = '&content_types=image'
        break
      case 'media':
        extra = '&content_types=video,audio'
        break
      case 'documents':
        extra = '&exclude_content_types=image,video,audio'
        break
    }
    return `${this.baseUri(
      endpoint,
      host
    )}?contextType=${contextType}&contextId=${contextId}${extra}`
  }
}

export default RceApiSource
