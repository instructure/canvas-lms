//
// Copyright (C) 2013 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('site')

export default function addPrivacyLinkToDialog($dialog) {
  if (!(ENV.ACCOUNT && ENV.ACCOUNT.privacy_policy_url)) return

  const $privacy = $('<a>', {
    href: ENV.ACCOUNT.privacy_policy_url,
    style: 'padding-left: 1em; line-height: 3em',
    class: 'privacy_policy_link',
    target: '_blank',
  })
  const $buttonPane = $dialog.closest('.ui-dialog').find('.ui-dialog-buttonpane')
  if (!$buttonPane.find('.privacy_policy_link').length) {
    $privacy.text(I18n.t('view_privacy_policy', 'View Privacy Policy'))
    $buttonPane.append($privacy)
  }
}
