/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

/* Hosted Canvas uses its own Inst-FS service as a file service to host and
 * serve user-uploaded files. This service however is served from an
 * Instructure domain name distinct from Canvas; "fixing" this is not feasible
 * because of the preponderance of "vanity domains", where Canvas is delivered
 * on a school's domain. This leads to the domain being treated as a
 * third-party despite being an integral part of the Canvas "ecosystem".
 *
 * Aggressive third-party tracking prevention by Safari 13.1+ breaks Inst-FS'
 * ability to use cookies to authenticate users' access to Canvas files. This
 * service worker allows the Canvas front-end to assert Inst-FS authorization
 * via HTTP headers instead of relying on browser cookies.
 *
 * However, it's preferrable to authenticate via cookie when possible, since
 * this allows Inst-FS to further redirect the user to a cookie-authenticated
 * CDN endpoint. As such, this ServiceWorker is only expected to be installed
 * for Safari 13.1+.
 */

// eslint-disable-next-line no-restricted-globals
self.addEventListener('fetch', function(event) {
  if (eligibleRequest(event.request)) {
    event.respondWith(fetchFile(event.request))
  }
})

function eligibleRequest(request) {
  const url = new URL(request.url)
  return request.method === 'GET' && request.mode !== 'navigate' && eligiblePath(url.pathname)
}

// most files links we care about look like this regex fragment with a context
// of some sort in front
const commonFilePath = `/files/[^/]+/(preview|download(.\\w+)?)`

function contextFilePath(context) {
  return new RegExp(`^/${context}/[^/]+${commonFilePath}$`)
}

const eligiblePaths = [
  contextFilePath(`accounts`),
  contextFilePath(`assessment_questions`),
  contextFilePath(`assignments`),
  contextFilePath(`courses`),
  contextFilePath(`groups`),
  contextFilePath(`quizzes/quiz_submissions`),
  contextFilePath(`quiz_statistics`),
  contextFilePath(`users`),

  // without a context is also valid
  new RegExp(`^${commonFilePath}$`),

  // these are some outliers that can still benefit from the service worker
  new RegExp(`^/images/thumbnails/(show/)?[^/]+/[^/]+$`),
  new RegExp(`^/api/lti/assignments/[^/]+/submissions/[^/]+/attachment/[^/]+$`)
]

function eligiblePath(pathname) {
  return eligiblePaths.some(function(candidate) {
    return candidate.test(pathname)
  })
}

function fetchFile(request) {
  // by providing this header, we're asking canvas to try and give us the
  // external location of the canvas file, with a short-lived authentication
  // token for the location, rather than redirecting us to it. if canvas can do
  // that, it will return that location in a JSON body as well as echoing back
  // the header so we can know it was honored.
  //
  // if the header is not included in the response, we just use the response
  // directly, successful or not.
  //
  // otherwise, we request the provided location, use the provided token in the
  // Authorization header. the external service is expected to accept this
  // token in lieu of a session cookie to authenticate the user.
  //
  // for non-inst-fs this will still redirect to s3, so we need cors mode, but
  // we only want to send credentials to canvas.
  const mode = 'cors'
  const credentials = 'same-origin'
  const headers = new Headers({'X-Canvas-File-Location': 'True'})
  return fetch(request, {mode, credentials, headers}).then(function(response) {
    if (response.ok && response.headers.has('X-Canvas-File-Location')) {
      return response.text().then(function(body) {
        // strip off "while(1);"
        const {location, token} = JSON.parse(body.substring(9))
        const instfsHeaders = new Headers({Authorization: `Bearer ${token}`})
        return fetch(location, {headers: instfsHeaders})
      })
    } else {
      return response
    }
  })
}
