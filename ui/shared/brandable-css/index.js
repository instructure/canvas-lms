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

import {isRTL} from '@canvas/i18n/rtlHelper'
import invariant from 'invariant'

const loadedStylesheets = {}

const brandableCss = {
  getCssVariant() {
    const contrast = window.ENV.use_high_contrast ? 'high_contrast' : 'normal_contrast'
    const rtl = isRTL() ? '_rtl' : ''
    return `new_styles_${contrast}${rtl}`
  },

  // see lib/brandable_css.rb#handlebars_index_json
  getHandlebarsIndex() {
    return window.BRANDABLE_CSS_HANDLEBARS_INDEX || [[], {}]
  },

  // combinedChecksum should be like '09f833ef7a'
  // and includesNoVariables should be true if this bundle does not
  // "@include" variables.scss, brand_variables.scss or variant_variables.scss
  urlFor(bundleName, {combinedChecksum, includesNoVariables}) {
    const brandAndVariant = includesNoVariables ? 'no_variables' : brandableCss.getCssVariant()

    return [
      window.ENV.ASSET_HOST || '',
      'dist',
      'brandable_css',
      brandAndVariant,
      `${bundleName}-${combinedChecksum}.css`,
    ].join('/')
  },

  // bundleName should be something like 'jst/foo'
  loadStylesheet(bundleName, opts) {
    if (bundleName in loadedStylesheets) return

    const linkElement = document.createElement('link')
    linkElement.rel = 'stylesheet'
    linkElement.href = brandableCss.urlFor(bundleName, opts)

    // give the person trying to track down a bug a hint on how this link tag got on the page
    linkElement.setAttribute('data-loaded-by-brandableCss', true)
    document.head.appendChild(linkElement)
  },

  loadStylesheetForJST({bundle, id}) {
    const [variants, bundles] = brandableCss.getHandlebarsIndex()

    invariant(
      bundles.hasOwnProperty(id),
      `requested to load stylesheet for template "${bundle}" (${id}) but no ` +
        `mapping is available for it!`
    )

    // "includesNoVariables" true; there's only one file regardless of variant
    if (bundles[id].length === 1) {
      return brandableCss.loadStylesheet(bundle, {
        combinedChecksum: bundles[id][0],
        includesNoVariables: true,
      })
    } else {
      // this can be a bit whoozy, remember the structure:
      //
      //     [
      //       [ 'a', 'b', 'c' ],
      //       ^^^^^^^^^^^^^^^^^ known variants, brandableCss.getCssVariant()
      //                         will be one of them
      //
      //       {
      //         "f0d": [
      //          ^^^ id
      //           "variant[0] checksum",
      //           "variant[1] checksum",
      //           0,
      //           ^ a ref that resolves into "variant[0] checksum"
      //           "variant[3] checksum"
      //         ]
      //       }
      //     ]
      //
      let checksum = bundles[id][variants.indexOf(brandableCss.getCssVariant())]

      if (typeof checksum === 'number') {
        checksum = bundles[id][checksum]
      }

      return brandableCss.loadStylesheet(bundle, {
        combinedChecksum: checksum,
        includesNoVariables: false,
      })
    }
  },
}
export default brandableCss
