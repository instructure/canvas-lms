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
});
