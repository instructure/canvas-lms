define([
  'i18n!account_authorization_configs',
  'str/htmlEscape',
  'jquery' /* $ */,
  'jquery.instructure_forms' /* formSubmit */,
  'jquery.keycodes' /* keycodes */,
  'jquery.loadingImg' /* loadingImage */
], function(I18n, htmlEscape, $) {

  $("#add_auth_select").change(function(event) {
    event.preventDefault();
    var new_type = $(this).find(":selected").val();
    if(new_type != "" || new_type != null){
      $(".new_auth").hide();
      $form = $("#" + new_type + "_form");
      $form.show();
      $form.find(":text:first").focus();
      $("#no_auth").css('display', 'none');
    }
  });

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