/*
 * Copyright (C) 2012 - present Instructure, Inc.
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
import htmlEscape from '@instructure/html-escape'
import React from 'react'
import ReactDOM from 'react-dom'
import AuthTypePicker from '../react/AuthTypePicker'
import authenticationProviders from './index'
import $ from 'jquery'
import ready from '@instructure/ready'
import '@canvas/jquery/jquery.instructure_forms' /* formSubmit */
import '@canvas/datetime/jquery'
import '@canvas/jquery-keycodes'
import '@canvas/loading-image'

const I18n = useI18nScope('authentication_providers')

ready(() => {
  const selectorNode = document.getElementById('add-authentication-provider')
  const authTypeOptions = JSON.parse(selectorNode.getAttribute('data-options'))

  authTypeOptions.unshift({
    name: I18n.t('Choose an authentication service'),
    value: 'default',
  })

  ReactDOM.render(
    <AuthTypePicker
      authTypes={authTypeOptions}
      onChange={authenticationProviders.changedAuthType}
    />,
    selectorNode
  )
})

$('.parent_reg_warning').click(function () {
  let msg
  const parent_reg_selected = $('#parent_reg_selected').attr('data-parent-reg-selected')
  if ($(this).is(':checked') && parent_reg_selected === 'true') {
    msg = I18n.t(
      'Another configuration is currently selected.  Selecting this configuration will deselect the other.'
    )
    $('.parent_warning_message').append(htmlEscape(msg))
    $.screenReaderFlashMessage(msg)
    $('.parent_form_message').addClass('ic-Form-message ic-Form-message--warning')
    $('.parent_form_message_layout').addClass('ic-Form-message__Layout')
    $('.parent_icon_warning').addClass('icon-warning')
  } else {
    $('.parent_warning_message').empty()
    $('.parent_form_message').removeClass('ic-Form-message ic-Form-message--warning')
    $('.parent_form_message_layout').removeClass('ic-Form-message__Layout')
    $('.parent_icon_warning').removeClass('icon-warning')
  }
})

$('.add_federated_attribute_button').click(function (event) {
  const $federated_attributes = $(this).closest('.federated_attributes')
  const $template = $federated_attributes.find('.attribute_template').clone(true)
  $template.removeClass('attribute_template')
  const $provider_attribute = $template
    .find("input[type!='checkbox']")
    .add($template.find('select'))
  const $canvas_attribute_select = $federated_attributes.find('.add_attribute .canvas_attribute')
  const $selected_canvas_attribute = $canvas_attribute_select.find('option:selected')
  const id_suffix = $template.data('idsuffix')
  const canvas_attribute_html = $selected_canvas_attribute.text()
  const checkbox_name = `authentication_provider[federated_attributes][${canvas_attribute_html}][provisioning_only]`
  const checkbox_id = `aacfa_${canvas_attribute_html}_provisioning_only_${id_suffix}`
  $template.find('.provisioning_only_column label').attr('for', checkbox_id)
  $template.find("input[type='checkbox']").attr('name', checkbox_name)
  $template.find("input[type='checkbox']").attr('id', checkbox_id)
  $template.find('.canvas_attribute_name').append($selected_canvas_attribute.text())
  const provider_attribute_name = `authentication_provider[federated_attributes][${canvas_attribute_html}][attribute]`
  const provider_attribute_id = `aacfa_${canvas_attribute_html}_attribute_${id_suffix}`
  $template.find('.provider_attribute_column label').attr('for', provider_attribute_id)
  $provider_attribute.attr('name', provider_attribute_name)
  $provider_attribute.attr('id', provider_attribute_id)
  $federated_attributes.find('tbody').append($template)
  $selected_canvas_attribute.remove()
  $template.show()
  $provider_attribute.focus()

  $federated_attributes.find('.no_federated_attributes').remove()
  $federated_attributes.find('table').show()
  if ($canvas_attribute_select.find('option').length === 0) {
    $federated_attributes.find('.add_attribute').hide()
  }
  event.preventDefault()
})

$('.remove_federated_attribute').click(function () {
  const $attribute_row = $(this).closest('tr')
  const $federated_attributes = $attribute_row.closest('.federated_attributes')
  const $canvas_attribute_select = $federated_attributes.find('.add_attribute .canvas_attribute')
  const canvas_attribute_html = $attribute_row.find('.canvas_attribute_name').text()
  $canvas_attribute_select.append(`<option>${canvas_attribute_html}</option>`)
  const $next = $attribute_row.nextAll(':visible').first().find('input:visible').first()
  $attribute_row.remove()
  $federated_attributes.find('.add_attribute').show()
  if ($federated_attributes.find('tbody tr:visible').length === 0) {
    $federated_attributes.find('table').hide()
    $federated_attributes.append(
      "<input type='hidden' name='authentication_provider[federated_attributes]' value='' class='no_federated_attributes'>"
    )
  }
  if ($next.length === 0) {
    $federated_attributes.find('.add_attribute .canvas_attribute').focus()
  } else {
    $next.focus()
  }
})

$('.jit_provisioning_checkbox').click(function () {
  const $provisioning_elements = $(this)
    .closest('.authentication_provider_form')
    .find('.provisioning_only_column')
  if ($(this).prop('checked')) {
    $provisioning_elements.show()
  } else {
    $provisioning_elements.hide()
    $provisioning_elements.find("input[type='checkbox']").removeAttr('checked')
  }
})
