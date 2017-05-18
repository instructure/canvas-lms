/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

define(['../../node_modules/axios'], function (axios) {
  // Add CSRF stuffs to make Canvas happy when we are making requests with axios
  axios.defaults.xsrfCookieName = '_csrf_token';
  axios.defaults.xsrfHeaderName = 'X-CSRF-Token';

  // Handle stringified IDs for JSON responses
  var originalDefaults = axios.defaults.headers.common['Accept'];
  axios.defaults.headers.common['Accept'] = 'application/json+canvas-string-ids, ' + originalDefaults;

  // Rails checks this header to decide if a request is an xhr request
  axios.defaults.headers.common['X-Requested-With'] = 'XMLHttpRequest';

  return axios;
});
