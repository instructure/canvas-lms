/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import addBank from './addBank'
import '@canvas/jquery/jquery.ajaxJSON' /* ajaxJSON */
import '@canvas/jquery/jquery.instructure_forms' /* formSubmit, getFormData, formErrors */
import 'jqueryui/dialog'
import '@canvas/jquery/jquery.instructure_misc_helpers' /* replaceTags */
import '@canvas/jquery/jquery.instructure_misc_plugins' /* confirmDelete, showIf, .dim */
import '@canvas/datetime/jquery'
import '@canvas/jquery-keycodes' /* keycodes */
import '@canvas/loading-image' /* loadingImage */
import '@canvas/util/templateData'

const I18n = useI18nScope('load_bank')
/* fillTemplateData, getTemplateData */

export default function loadBanks() {
  const url = $('#bank_urls .managed_banks_url').attr('href')
  const $dialog = $('#move_question_dialog')
  $dialog.find('li.message').text(I18n.t('loading_banks', 'Loading banks...'))
  $.ajaxJSON(
    url,
    'GET',
    {},
    data => {
      for (let idx = 0; idx < data.length; idx++) {
        addBank(data[idx].assessment_question_bank)
      }
      $dialog.addClass('loaded')
      $dialog.find('li.bank.blank').show()
      $dialog.find('li.message').hide()
    },
    _data => {
      $dialog.find('li.message').text(I18n.t('error_loading_banks', 'Error loading banks'))
    }
  )
}
