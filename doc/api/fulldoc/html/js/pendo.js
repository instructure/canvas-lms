/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

function hasConsent() {
  return (
    typeof localStorage !== 'undefined' &&
    localStorage.getItem('canvas_api_doc_consent_accepted') === 'true'
  )
}
(function (a) {
  (function (p, e, n, d, o) {
    var v, w, x, y, z
    o = p[d] = p[d] || {}
    o._q = o._q || []
    v = ['initialize', 'identify', 'updateOptions', 'pageLoad', 'track']
    for (w = 0, x = v.length; w < x; ++w)
      (function (m) {
        o[m] =
          o[m] ||
          function () {
            o._q[m === v[0] ? 'unshift' : 'push']([m].concat([].slice.call(arguments, 0)))
          }
      })(v[w])
    y = e.createElement(n)
    y.async = !0
    y.src = 'https://cdn.pendo.io/agent/static/' + a + '/pendo.js'
    z = e.getElementsByTagName(n)[0]
    z.parentNode.insertBefore(y, z)
    y.onload = function () {
      if (hasConsent()) pendo.initialize({})
    }
  })(window, document, 'script', 'pendo')
})('854196ad-8ed4-46ad-470f-506461c70149')
