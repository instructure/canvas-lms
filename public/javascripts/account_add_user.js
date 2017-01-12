require([
  'i18n!accounts' /* I18n.t */,
  'jquery' /* $ */,
  'compiled/util/addPrivacyLinkToDialog',
  'underscore',
  'user_sortable_name',
  'jquery.instructure_forms' /* formSubmit */,
  'jqueryui/dialog',
  'compiled/jquery/fixDialogButtons' /* fix dialog formatting */,
  'compiled/jquery.rails_flash_notifications'
], function(I18n, $, addPrivacyLinkToDialog, _) {

  $(".add_user_link").click(function(event) {
    event.preventDefault();
    $("#add_user_form :text").val("");
    var $dialog = $("#add_user_dialog");
    $dialog.dialog({
      title: I18n.t('add_user_dialog_title', "Add a New User"),
      width: 500
    }).fixDialogButtons();
    addPrivacyLinkToDialog($dialog);
    $("#add_user_form :text:visible:first").focus().select();
  });
  $("#add_user_form").formSubmit({
    formErrors: false,
    required: ['user[name]', 'pseudonym[unique_id]'],
    beforeSubmit: function(data) {
      $(this).find("button").attr('disabled', true)
        .filter(".submit_button").text(I18n.t('adding_user_message', "Adding User..."));
    },
    success: function(data) {
      $(this).find("button").attr('disabled', false)
        .filter(".submit_button").text(I18n.t('add_user_button', "Add User"));
      var user = data.user.user || data.user;
      var link = "<a href='/users/" + user.id + "'>$1</a>"
      var message = '';
      if(data.message_sent) {
        message = I18n.t('user_added_message_sent_message', '*%{user}* successfully added! They should receive an email confirmation shortly.', {user: user.name, wrapper: link});
      } else {
        message = I18n.t('user_added_message', '*%{user}* successfully added!', {user: user.name, wrapper: link});
      }
      $.flashMessage(message);
      $("#add_user_dialog").dialog('close');
    },
    error: function(data) {
      errorData = {};

      // Email errors
      if(data.pseudonym.unique_id){
        errorList = [];

        var messages = {
          too_long: I18n.t("Login is too long"),
          invalid: I18n.t("Login is invalid: must be alphanumeric or an email address")
        };
        var errors = _.uniq(_.map(data.pseudonym.unique_id, function(i){ return i.message; }));
        _.each(errors, function(i){
          errorList.push(messages[i] ? messages[i] : i);
        });

        errorData['unique_id'] = errorList.join(', ');
      }

      // SIS ID taken error
      if (data.pseudonym.sis_user_id) {
        errorList = [];

        var errors = _.uniq(_.map(data.pseudonym.sis_user_id, function(i){ return i.message; }));
        _.each(errors, function(i){
          errorList.push(i);
        });

        errorData['sis_user_id'] = errorList.join(', ');
      }

      $(this).formErrors(errorData);

      $(this).find("button").attr('disabled', false)
        .filter(".submit_button").text(I18n.t('user_add_failed_message', "Adding User Failed, please try again"));
    }
  });
  $("#add_user_dialog .cancel_button").click(function() {
    $("#add_user_dialog").dialog('close');
  });
});

