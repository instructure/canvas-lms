/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import {get} from 'jquery'

import brandableVariables from '../stylesheets/brandable_variables.json'

const images = brandableVariables
  .reduce((acc, cur) => acc.concat(cur.variables), []) // flatten
  .filter(e => e.type === 'image')
  .map(e => e.variable_name)

const variablesMap = window.CANVAS_ACTIVE_BRAND_VARIABLES || {}

// makes a regex that will match any occurrence of any of the brandable css variables in a stylesheet
const variablesRegex = new RegExp(
  `\\bvar\\(\\s*--(${Object.keys(variablesMap).join('|')})\\s*\\)`,
  'g'
)

export default function processSheet(element) {
  const replaceCssVariablesWithStaticValues = cssText => {
    let replacedAtLeastOneVar = false
    const replacedCss = cssText.replace(variablesRegex, (match, name) => {
      // if this variable exists in CANVAS_ACTIVE_BRAND_VARIABLES, replace it with it's value.
      // otherwise, leave it unchanged
      let replacement = variablesMap[name]
      if (replacement) {
        replacedAtLeastOneVar = true

        // the json contains raw urls for images, wrap them in css `url(...)` syntax.
        if (images.includes(name)) replacement = `url('${replacement}')`

        return replacement
      } else {
        return match
      }
    })
    if (replacedAtLeastOneVar) element.sheet.cssText = replacedCss
    // give anyone trying to debug things a hint that we processed this file
    element.setAttribute('data-css-variables-polyfilled', replacedAtLeastOneVar)
  }

  const url = element.href
  const cacheKey = `cssPolyfillCache-${url}`
  const cached = sessionStorage[cacheKey]
  if (cached) {
    replaceCssVariablesWithStaticValues(cached)
  } else {
    // Edge tries to reuse the cached resource it downloaded for the <link... tag for this,
    // but since when it made that request it didn't include an `origin:` request header,
    // cloudfront won't include the `access-control-allow-origin: *` response header.
    // so when it tries to reuse that response it fails with "No access-control-allow-origin header".
    // I wish Edge would either treat it as a new request (because the new request has different request headers)
    // and issue a new http request or that cloudfront would include `access-control-allow-origin: *` even
    // when an `origin:` header is not present, then we wouldn't need this.
    const urlWithCacheBuster = `${url}?forceEdgeToDownloadNewResourceSoItHasAccessControlAllowOriginHeader`
    get(urlWithCacheBuster).then(cssText => {
      replaceCssVariablesWithStaticValues(cssText)
      sessionStorage.setItem(cacheKey, cssText)
    })
  }
}

// run polyfill against all stylesheets on the page
;[].forEach.call(document.querySelectorAll('link[rel="stylesheet"]'), processSheet)
