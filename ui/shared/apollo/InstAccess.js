/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
class InstAccess {
  // This class is intended to be used in combination with our
  // ApolloClient when talking to the API Gateway rather than
  // Canvas directly.  It should provide an in-memory place to store
  // the access token (JWT) we need for gateway access without needing to
  // put it in local storage or an easy to poke at global variable.
  //  When we substitute the `gatewayAuthenticatedFetch` as the "fetch"
  // option for an Apollo HttpLink, it will add an inst access token
  // to the header (fetching one if necessary), and should refresh
  // the token and retry once if it ever receives a 4xx (which we
  // would expect in the case when an InstAccess token has passed it's
  // expiration window).
  constructor(options = {}) {
    this.instAccessToken = options.token || null
    this.fetchImpl = options.preferredFetch || fetch
    this.docImpl = options.preferredDocument || document
  }

  async gatewayAuthenticatedFetch(uri, options) {
    if (this.instAccessToken === null) {
      this.instAccessToken = await this.fetchFreshAccessToken()
    }
    options.headers ||= {}
    options.headers.authorization = `Bearer ${this.instAccessToken}`
    const firstTryResponse = await this.fetchImpl(uri, options)
    const statusCode = firstTryResponse.status
    if (statusCode >= 400 && statusCode < 500) {
      // we might have an expired token, let's try to refresh it
      this.instAccessToken = await this.fetchFreshAccessToken()
      options.headers.authorization = `Bearer ${this.instAccessToken}`
      return this.fetchImpl(uri, options)
    }
    return firstTryResponse
  }

  // Internal only.
  //
  // InstAccess tokens are JWTs that are encrypted
  // in a way only the API Gateway can read.  They have a
  // relatively short expiration window, so go invalid quickly.
  // This function is purposely stateless so that any time we hit
  // an expiration issue in talking to the gateway, it's easy to just get another token
  // with the user's cookie.
  async fetchFreshAccessToken() {
    const csrfToken = this.readCsrfFromCookie()
    const fetchOptions = {
      method: 'POST',
      credentials: 'same-origin',
      mode: 'same-origin',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
        'X-CSRF-Token': csrfToken
      }
    }
    const tokenResponse = await this.fetchImpl('/api/v1/inst_access_tokens', fetchOptions)
    const tokenBody = await tokenResponse.json()
    return tokenBody.token
  }

  // Internal only.
  //
  // canvas keeps it's csrf token in a cookie that's readable by js.
  // Appending this token as a header adds some complexity, but is
  // far preferable to the simpler strategy of skipping csrf verification
  // for API invocations. Please don't do that.
  // https://guides.rubyonrails.org/security.html#csrf-countermeasures
  readCsrfFromCookie() {
    return decodeURIComponent(
      this.docImpl.cookie
        .split(';')
        .map(c => c.trim())
        .filter(c => c.startsWith('_csrf_token='))[0]
        .split('=')[1]
    )
  }
}

export default InstAccess
