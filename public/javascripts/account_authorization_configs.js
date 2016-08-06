define([
  'i18n!account_authorization_configs',
  'str/htmlEscape',
  'react',
  'jsx/authentication_providers/AuthTypePicker',
  'authentication_providers',
  'jquery' /* $ */,
  'jquery.instructure_forms' /* formSubmit */,
  'jquery.keycodes' /* keycodes */,
  'jquery.loadingImg' /* loadingImage */
], function(I18n, htmlEscape, React, AuthTypePicker, authenticationProviders, $) {

  var Picker = React.createFactory(AuthTypePicker);
  var selectorNode = document.getElementById("add-authentication-provider");
  var authTypeOptions = JSON.parse(selectorNode.getAttribute("data-options"));
  var authTypePicker = Picker({
    authTypes: authTypeOptions,
    onChange: authenticationProviders.changedAuthType
  });
  React.render(authTypePicker, selectorNode);

  $('.parent_reg_warning').click(function() {
    var parent_reg_selected = $('#parent_reg_selected').attr('data-parent-reg-selected');
    if($(this).is(":checked") && parent_reg_selected == 'true') {
      msg = I18n.t("Another configuration is currently selected.  Selecting this configuration will deselect the other.");
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
    var canvas_attribute_html = $selected_canvas_attribute.text();
    var checkbox_name = "authentication_provider[federated_attributes][" + canvas_attribute_html + "][provisioning_only]"
    $template.find(".provisioning_only_column label").attr('for', checkbox_name);
    $template.find("input[type='checkbox']").attr('name', checkbox_name);
    $template.find("input[type='checkbox']").attr('id', checkbox_name);
    $template.find('.canvas_attribute').append($selected_canvas_attribute.text());
    var provider_attribute_name = "authentication_provider[federated_attributes][" + canvas_attribute_html + "][attribute]";
    $template.find('.provider_attribute_column label').attr('for', provider_attribute_name);
    $provider_attribute.attr('name', provider_attribute_name);
    $provider_attribute.attr('id', provider_attribute_name);
    $federated_attributes.find('tbody').append($template);
    $selected_canvas_attribute.remove();
    $template.show();
    $provider_attribute.focus();

    $federated_attributes.find('.no_federated_attributes').remove();
    if ($canvas_attribute_select.find('option').length === 0) {
      $federated_attributes.find('.add_attribute').hide();
    }
    event.preventDefault();
  });

  $('.remove_federated_attribute').click(function() {
    var $attribute_row = $(this).closest('tr')
    var $federated_attributes = $attribute_row.closest('.federated_attributes')
    var $canvas_attribute_select = $federated_attributes.find('.add_attribute .canvas_attribute');
    var canvas_attribute_html = $attribute_row.find('.canvas_attribute').text();
    $canvas_attribute_select.append("<option>" + canvas_attribute_html + "</option>");
    var $next = $attribute_row.nextAll(':visible').first().find('input:visible').first();
    $attribute_row.remove();
    $federated_attributes.find('.add_attribute').show();
    if ($federated_attributes.find('tbody tr:visible').length === 0) {
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
});
