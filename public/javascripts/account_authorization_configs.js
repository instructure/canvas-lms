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

import I18n from 'i18n!authentication_providers'
import htmlEscape from './str/htmlEscape'
import React from 'react'
import ReactDOM from 'react-dom'
import AuthTypePicker from 'jsx/authentication_providers/AuthTypePicker'
import authenticationProviders from 'authentication_providers'
import $ from 'jquery'
import './jquery.instructure_forms' /* formSubmit */
import './jquery.keycodes'
import './jquery.loadingImg'

  var Picker = React.createFactory(AuthTypePicker);
  var selectorNode = document.getElementById('add-authentication-provider');
  var authTypeOptions = JSON.parse(selectorNode.getAttribute('data-options'));
  authTypeOptions.unshift({
    name: I18n.t('Choose an authentication service'),
    value: 'default'
  });
  var authTypePicker = Picker({
    authTypes: authTypeOptions,
    onChange: authenticationProviders.changedAuthType
  });
  ReactDOM.render(authTypePicker, selectorNode);

  $('.parent_reg_warning').click(function() {
    var msg;
    var parent_reg_selected = $('#parent_reg_selected').attr('data-parent-reg-selected');
    if($(this).is(":checked") && parent_reg_selected == 'true') {
      msg = I18n.t('Another configuration is currently selected.  Selecting this configuration will deselect the other.');
      $('.parent_warning_message').append(htmlEscape(msg));
      $.screenReaderFlashMessage(msg);
      $('.parent_form_message').addClass('ic-Form-message ic-Form-message--warning');
      $('.parent_form_message_layout').addClass('ic-Form-message__Layout');
      $('.parent_icon_warning').addClass('icon-warning');
    }
    else {
      $('.parent_warning_message').empty();
      $('.parent_form_message').removeClass('ic-Form-message ic-Form-message--warning');
      $('.parent_form_message_layout').removeClass('ic-Form-message__Layout');
      $('.parent_icon_warning').removeClass('icon-warning');
    }
  });

  $('.add_federated_attribute_button').click(function(event) {
    var $federated_attributes = $(this).closest('.federated_attributes');
    var $template = $federated_attributes.find('.attribute_template').clone(true);
    $template.removeClass('attribute_template');
    var $provider_attribute = $template.find("input[type!='checkbox']").add($template.find("select"));
    var $canvas_attribute_select = $federated_attributes.find('.add_attribute .canvas_attribute');
    var $selected_canvas_attribute = $canvas_attribute_select.find("option:selected");
    var id_suffix = $template.data("idsuffix");
    var canvas_attribute_html = $selected_canvas_attribute.text();
    var checkbox_name = "authentication_provider[federated_attributes][" + canvas_attribute_html + "][provisioning_only]"
    var checkbox_id = "aacfa_" + canvas_attribute_html + "_provisioning_only_" + id_suffix;
    $template.find(".provisioning_only_column label").attr('for', checkbox_id);
    $template.find("input[type='checkbox']").attr('name', checkbox_name);
    $template.find("input[type='checkbox']").attr('id', checkbox_id);
    $template.find('.canvas_attribute_name').append($selected_canvas_attribute.text());
    var provider_attribute_name = "authentication_provider[federated_attributes][" + canvas_attribute_html + "][attribute]";
    var provider_attribute_id = "aacfa_" + canvas_attribute_html + "_attribute_" + id_suffix;
    $template.find('.provider_attribute_column label').attr('for', provider_attribute_id);
    $provider_attribute.attr('name', provider_attribute_name);
    $provider_attribute.attr('id', provider_attribute_id);
    $federated_attributes.find('tbody').append($template);
    $selected_canvas_attribute.remove();
    $template.show();
    $provider_attribute.focus();

    $federated_attributes.find('.no_federated_attributes').remove();
    $federated_attributes.find('table').show();
    if ($canvas_attribute_select.find('option').length === 0) {
      $federated_attributes.find('.add_attribute').hide();
    }
    event.preventDefault();
  });

  $('.remove_federated_attribute').click(function() {
    var $attribute_row = $(this).closest('tr')
    var $federated_attributes = $attribute_row.closest('.federated_attributes')
    var $canvas_attribute_select = $federated_attributes.find('.add_attribute .canvas_attribute');
    var canvas_attribute_html = $attribute_row.find('.canvas_attribute_name').text();
    $canvas_attribute_select.append("<option>" + canvas_attribute_html + "</option>");
    var $next = $attribute_row.nextAll(':visible').first().find('input:visible').first();
    $attribute_row.remove();
    $federated_attributes.find('.add_attribute').show();
    if ($federated_attributes.find('tbody tr:visible').length === 0) {
      $federated_attributes.find('table').hide();
      $federated_attributes.append("<input type='hidden' name='authentication_provider[federated_attributes]' value='' class='no_federated_attributes'>")
    }
    if ($next.length === 0) {
      $federated_attributes.find('.add_attribute .canvas_attribute').focus();
    } else {
      $next.focus();
    }
  });

  $('.jit_provisioning_checkbox').click(function() {
    var $provisioning_elements = $(this).closest('.authentication_provider_form').find('.provisioning_only_column');
    if ($(this).attr('checked')) {
      $provisioning_elements.show();
    } else {
      $provisioning_elements.hide();
      $provisioning_elements.find("input[type='checkbox']").removeAttr('checked');
    }
  });
