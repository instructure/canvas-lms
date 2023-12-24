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
import '@canvas/jquery/jquery.ajaxJSON' /* ajaxJSON */
import '@canvas/jquery/jquery.instructure_forms' /* formSubmit, getFormData, formErrors */
import 'jqueryui/dialog'
import '@canvas/jquery/jquery.instructure_misc_helpers' /* replaceTags */
import '@canvas/jquery/jquery.instructure_misc_plugins' /* confirmDelete, showIf, .dim */
import '@canvas/datetime/jquery'
import '@canvas/jquery-keycodes' /* keycodes */
import '@canvas/loading-image' /* loadingImage */
import '@canvas/util/templateData'

const I18n = useI18nScope('add_bank')
/* fillTemplateData, getTemplateData */

export default function addBank(bank) {
  const current_question_bank_id = $('#bank_urls .current_question_bank_id').text()
  if (bank.id == current_question_bank_id) {
    return
  }
  const $dialog = $('#move_question_dialog')
  const $bank = $dialog.find('li.bank.blank:first').clone(true).removeClass('blank')

  $bank
    .find('input')
    .attr('id', 'question_bank_' + bank.id)
    .val(bank.id)
  $bank
    .find('label')
    .attr('for', 'question_bank_' + bank.id)
    .find('.bank_name')
    .text(bank.title || I18n.t('default_name', 'No Name'))
    .end()
    .find('.context_name')
    .text(bank.cached_context_short_name)
  $bank.show().insertBefore($dialog.find('ul.banks .bank.blank:last'))
}
