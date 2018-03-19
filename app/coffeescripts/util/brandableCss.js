//
// Copyright (C) 2015 - present Instructure, Inc.
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

import {isRTL} from 'jsx/shared/helpers/rtlHelper'

const loadedStylesheets = {}

const brandableCss = {

  getCssVariant () {
    const variant = window.ENV.use_responsive_layout ? 'responsive_layout' : 'new_styles'
    const contrast = window.ENV.use_high_contrast ? 'high_contrast' : 'normal_contrast'
    const rtl = isRTL() ? '_rtl' : ''
    return `${variant}_${contrast}${rtl}`
  },

  // combinedChecksum should be like '09f833ef7a'
  // and includesNoVariables should be true if this bundle does not
  // "@include" variables.scss, brand_variables.scss or variant_variables.scss
  urlFor (bundleName, {combinedChecksum, includesNoVariables}) {
    const brandAndVariant = includesNoVariables
      ? 'no_variables'
      : brandableCss.getCssVariant()

    return [
      window.ENV.ASSET_HOST || '',
      'dist',
      'brandable_css',
      brandAndVariant,
      `${bundleName}-${combinedChecksum}.css`
    ].join('/')
  },

  // bundleName should be something like 'jst/foo'
  loadStylesheet (bundleName, opts) {
    if (bundleName in loadedStylesheets) return

    const linkElement = document.createElement('link')
    linkElement.rel = 'stylesheet'
    linkElement.href = brandableCss.urlFor(bundleName, opts)

    // give the person trying to track down a bug a hint on how this link tag got on the page
    linkElement.setAttribute('data-loaded-by-brandableCss', true)
    document.head.appendChild(linkElement)

    // For browsers that don't support css varibles (right now only IE11), we need to pass
    // this newly injected stylesheet to the cssVariables polyfill so that it can polyfill it.
    // The polyfill will only exist on window in browsers that need it.
    if (window.canvasCssVariablesPolyfill) window.canvasCssVariablesPolyfill(linkElement)
  }
}
export default brandableCss
