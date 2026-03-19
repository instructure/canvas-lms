/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import $ from 'jquery'
import ready from '@instructure/ready'

// ENV.crowdsourced_locales is a page-specific property not in GlobalEnv

ready(() => {
  const $select = $('select.locale')

  const $warningLink = $('i.locale-warning')
  $warningLink.hide()

  function checkWarningIcon() {
    const selectedLocale = $select.val()
    // @ts-expect-error - crowdsourced_locales is a page-specific ENV property
    if (typeof selectedLocale === 'string' && ENV.crowdsourced_locales.includes(selectedLocale)) {
      $warningLink.show()
    } else {
      $warningLink.hide()
    }
  }

  $select.change(() => checkWarningIcon())

  return checkWarningIcon()
})
