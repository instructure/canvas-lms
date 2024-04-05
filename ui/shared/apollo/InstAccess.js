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
import getCookie from '@instructure/get-cookie'

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
    this.fetchImpl =
      options.preferredFetch ||
      (async (uri, opts) => {
        return fetch(uri, opts)
      })
  }

}

export default InstAccess
