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

import normalizeLocale from './rce/normalizeLocale'
import {renderIntoDiv as render} from './rce/root'
import {headerFor, originFromHost} from './rcs/api'
import getTranslations from './getTranslations'
import defaultTinymceConfig from './defaultTinymceConfig'
import {setLocale} from './common/natcompare'
import {Mathml} from './enhance-user-content/mathml'

export * from './enhance-user-content/index'

export const defaultConfiguration = defaultTinymceConfig
export {instuiPopupMountNode} from './util/fullscreenHelpers'
export {Mathml}

export function renderIntoDiv(editorEl, props, cb) {
  const language = normalizeLocale(props.language)
  setLocale(language)
  if (process.env.BUILD_LOCALE || language === 'en') {
    render(editorEl, props, cb)
  } else {
    // unlike the pretranslated builds, in the default, non-pretranslated build,
    // this will cause a new network round trip to get all the locale info the rce
    // and tinymce need.
    getTranslations(language)
      .then(() => render(editorEl, props, cb))
      .catch(err => {
        // eslint-disable-next-line no-console
        console.error(
          'Failed loading the language file for',
          language,
          'RCE is falling back to English.\n Cause:',
          err
        )
        render(editorEl, props, cb)
      })
  }
}

export function getRCSAuthenticationHeaders(jwt) {
  return headerFor(jwt)
}

export function getRCSOriginFromHost(host) {
  return originFromHost(host)
}
