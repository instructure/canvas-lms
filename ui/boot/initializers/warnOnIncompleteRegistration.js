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
import {useScope as useI18nScope} from '@canvas/i18n'
import template from './jst/incompleteRegistrationWarning.handlebars'

const I18n = useI18nScope('incompleteregistration')

if (ENV.INCOMPLETE_REGISTRATION) {
  $(template({email: ENV.USER_EMAIL}))
    .appendTo($('body'))
    .dialog({
      title: I18n.t('welcome_to_canvas', 'Welcome to Canvas!'),
      width: 400,
      resizable: false,
      buttons: [
        {
          text: I18n.t('get_started', 'Get Started'),
          click() {
            $(this).dialog('close')
          },
          class: 'btn-primary',
        },
      ],
      modal: true,
      zIndex: 1000,
    })
}
