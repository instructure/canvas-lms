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
import I18n from 'i18n!external_content.cancel'

let parentWindow
window.parentWindow = window.parent
window.callback = ENV.service
while (parentWindow && !parentWindow[callback]) {
  parentWindow = parentWindow.parent
}
parentWindow.$(parentWindow).trigger('externalContentCancel')
if (parentWindow[callback] && parentWindow[callback].cancel) {
  parentWindow[callback].cancel()
  setTimeout(
    () =>
      $('#dialog_message').text(
        I18n.t('popup_success', 'Canceled. This popup should close on its own...')
      ),
    1000
  )
} else {
  $('#dialog_message').text(
    I18n.t(
      'popup_failure',
      "Cannot find the parent window, you'll need to close this popup manually."
    )
  )
}
