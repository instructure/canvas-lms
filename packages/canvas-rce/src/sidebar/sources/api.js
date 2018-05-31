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
import {downloadToWrap} from '../../common/fileUrl'
import {parse} from 'url'

function headerFor(jwt) {
  return {Authorization: 'Bearer ' + jwt}
}

// filter a response to raise an error on a 400+ status
function checkStatus(response) {
  if (response.status < 400) {
    return response
  } else {
    var error = new Error(response.statusText)
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

class RceApiSource {
  constructor(options = {}) {
    this.jwt = options.jwt
    this.host = options.host
    this.refreshToken = options.refreshToken || defaultRefreshTokenHandler
  }

  getSession() {
    const headers = headerFor(this.jwt)
    const uri = this.baseUri('session')
    return this.apiFetch(uri, headers)
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

  initializeImages() {
    return {
      records: [],
      bookmark: undefined,
      hasMore: false,
      isLoading: false,
      requested: false
    }
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

  // fetches folders for the given context to upload files to
  fetchFolders(props, bookmark) {
    let headers = headerFor(this.jwt)
    let uri = bookmark || this.uriFor('folders/all', props)
    return this.apiFetch(uri, headers)
  }

  fetchImages(props) {
    if (props.bookmark) {
      return this.apiFetch(props.bookmark, headerFor(this.jwt))
    } else {
      let headers = headerFor(this.jwt)
      let uri = this.uriFor('images', props)
      return this.apiFetch(uri, headers)
    }
  }

  preflightUpload(fileProps, apiProps) {
    let headers = headerFor(this.jwt)
    let uri = this.baseUri('upload', apiProps.host)
    let body = {
      contextId: apiProps.contextId,
      contextType: apiProps.contextType,
      file: fileProps,
      no_redirect: true
    }
    return this.apiPost(uri, headers, body)
  }

  uploadFRD(fileDomObject, preflightProps) {
    var data = new window.FormData()
    Object.keys(preflightProps.upload_params).forEach(uploadProp => {
      data.append(uploadProp, preflightProps.upload_params[uploadProp])
    })
    data.append('file', fileDomObject)
    let fetchOptions = {method: 'POST', body: data}
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
      let {pathname} = parse(uploadResults.location)
      let matchData = pathname.match(/^\/api\/v1\/files\/(\d+)$/)
      if (!matchData) {
        let error = new Error('cannot determine file ID from location')
        error.location = uploadResults.location
        throw error
      }
      let fileId = matchData[1]
      return this.getFile(fileId)
    } else {
      // local-storage upload, this _is_ the attachment information
      return Promise.resolve(uploadResults)
    }
  }

  setUsageRights(fileId, usageRights) {
    let headers = headerFor(this.jwt)
    let uri = this.baseUri('usage_rights')
    let body = {fileId, ...usageRights}
    return this.apiPost(uri, headers, body)
  }

  searchFlickr(term, apiProps) {
    let headers = headerFor(this.jwt)
    let base = this.baseUri('flickr_search', apiProps.host)
    let uri = `${base}?term=${encodeURIComponent(term)}`
    return this.apiFetch(uri, headers)
  }

  getFile(id) {
    let headers = headerFor(this.jwt)
    let base = this.baseUri('file')
    let uri = `${base}/${id}`
    return this.apiFetch(uri, headers).then(normalizeFileData)
  }

  // @private
  apiFetch(uri, headers) {
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
      .then(parseResponse)
  }

  // @private
  apiPost(uri, headers, body) {
    headers = Object.assign({}, headers, {
      'Content-Type': 'application/json'
    })
    let fetchOptions = {
      method: 'POST',
      headers: headers,
      body: JSON.stringify(body)
    }
    uri = this.normalizeUriProtocol(uri)
    return fetch(uri, fetchOptions)
      .then(response => {
        if (response.status == 401) {
          // retry once with fresh token
          return this.buildRetryHeaders(fetchOptions.headers).then(newHeaders => {
            let newOptions = Object.assign({}, fetchOptions, {
              headers: newHeaders
            })
            return fetch(uri, newOptions)
          })
        } else {
          return response
        }
      })
      .then(checkStatus)
      .then(parseResponse)
  }

  // @private
  normalizeUriProtocol(uri, windowOverride) {
    let windowHandle = windowOverride || (typeof window !== 'undefined' ? window : undefined)
    if (windowHandle && windowHandle.location && windowHandle.location.protocol == 'https:') {
      return uri.replace('http://', 'https://')
    }
    return uri
  }

  // @private
  buildRetryHeaders(headers) {
    return new Promise(resolve => {
      this.refreshToken(freshToken => {
        this.jwt = freshToken
        let freshHeader = headerFor(freshToken)
        let mergedHeaders = Object.assign({}, headers, freshHeader)
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
    } else if (host.substr(0, 4) !== 'http') {
      host = `//${host}`
      let windowHandle = windowOverride || (typeof window !== 'undefined' ? window : undefined)
      if (
        host.length > 0 &&
        windowHandle &&
        windowHandle.location &&
        windowHandle.location.protocol
      ) {
        host = `${windowHandle.location.protocol}${host}`
      }
    }
    return `${host}/api/${endpoint}`
  }

  // returns the URI to use with the fetchPage method to fetch the first page of
  // the given endpoint. e.g. for wikiPages it might return:
  //
  //   //rce.docker/api/wikiPages?context_type=course&context_id=42
  //
  uriFor(endpoint, props) {
    let {host, contextType, contextId} = props
    return `${this.baseUri(endpoint, host)}?contextType=${contextType}&contextId=${contextId}`
  }
}

export default RceApiSource
