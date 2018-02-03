//
// Copyright (C) 2012 - present Instructure, Inc.
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
import privacyNoticeTpl from 'jst/profiles/notifications/privacyNotice'
import '../jquery/fixDialogButtons'

export default function privacyNotice () {
  if (ENV.READ_PRIVACY_INFO || !ENV.ACCOUNT_PRIVACY_NOTICE) return

  const $privacyNotice = $(privacyNoticeTpl())
  $privacyNotice
    .appendTo('body')
    .dialog({
      close: (event, ui) => $.post('/profile', {_method: 'put', privacy_notice: 1}),
      title: $privacyNotice.data('title')
    })
    .fixDialogButtons()
}
