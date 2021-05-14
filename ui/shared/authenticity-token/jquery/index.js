//
// Copyright (C) 2014 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import $ from 'jquery'
import getCookie from 'get-cookie'

const authenticity_token = () => getCookie('_csrf_token')

const getHostname = function (href) {
  const a = document.createElement('a')
  a.href = href
  return a.hostname
}

const isCrossSite = function (href) {
  // eslint-disable-next-line no-restricted-globals
  return getHostname(href) !== location.hostname
}

const injectTokenIntoLocalRequests = function () {
  if (isCrossSite(this.action)) {
    return
  }

  $(this).find('input[name="authenticity_token"]').val(authenticity_token())
}

$(document).on('submit', 'form', injectTokenIntoLocalRequests)

// return a function to be used elsewhere
export default authenticity_token

// for testing
export {isCrossSite}
