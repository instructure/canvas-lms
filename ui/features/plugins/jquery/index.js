/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import '@canvas/jquery/jquery.instructure_misc_plugins'

const I18n = useI18nScope('plugins')
/* showIf */

$(document).on('submit', 'form.edit_plugin_setting', function () {
  $(this)
    .find('button')
    .prop('disabled', true)
    .filter('.save_button')
    .text(I18n.t('buttons.saving', 'Saving...'))
})
$(document).ready(function () {
  $('.disabled_checkbox')
    .change(function () {
      $('#settings .plugin_settings').showIf(!$(this).prop('checked'))
    })
    .change()
})
