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

import $ from 'jquery'
import 'jqueryui/dialog'
import developerKeyFormTemplate from 'jst/developer_key_form'
import I18n from 'i18n!react_developer_keys'
import store from '../store/store'
import actions from '../actions/developerKeysActions'

export default function buildForm (key = {}) {
  const keyModified = Object.assign({}, key)
  keyModified._formAction = keyModified.id ? '/api/v1/developer_keys' : ENV.accountEndpoint

  if (!keyModified.name && keyModified.id) {
    keyModified.name = I18n.t('unnamed_tool', 'Unnamed Tool')
  }

  const $form = $(developerKeyFormTemplate(keyModified))
  $form.formSubmit({
    beforeSubmit () {
      $('#edit_dialog button.submit').text(I18n.t('button.saving', 'Saving Key...'))
    },
    disableWhileLoading: true,
    success (returnedKey) {
      $('#edit_dialog').dialog('close')
      if (keyModified.id) {
        store.dispatch(actions.listDeveloperKeysReplace(returnedKey))
      } else {
        store.dispatch(actions.listDeveloperKeysPrepend(returnedKey))
      }
    },
    error () {
      $('#edit_dialog button.submit').text(I18n.t('button.saving_failed', 'Saving Key Failed'))
    }
  })
  return $form
}

$('.add_key').click((event) => {
  event.preventDefault()
  const $form = buildForm()
  $('#edit_dialog').empty().append($form).dialog('open')
})

$('#edit_dialog')
  .html(developerKeyFormTemplate({}))
  .dialog({autoOpen: false, width: 400})
  .on('click', '.cancel', () => $('#edit_dialog').dialog('close'))
