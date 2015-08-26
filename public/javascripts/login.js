define([
  'i18n!pseudonyms.login' /* I18n.t */,
  'jquery' /* $ */,
  'str/htmlEscape',
  'compiled/registration/signupDialog',
  'jquery.fancyplaceholder' /* fancyPlaceholder */,
  'jquery.google-analytics' /* trackPage, trackPageview */,
  'jquery.instructure_forms' /* formSubmit, getFormData, formErrors, errorBox */,
  'jquery.loadingImg' /* loadingImage */,
  'compiled/jquery.rails_flash_notifications'
], function(I18n, $, htmlEscape, signupDialog) {

  var loginUtils = {
    validResetEmail: function(email){
      var emailRegexp = new RegExp("[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?");
      var regexMatch = email.match(emailRegexp);
      return regexMatch !== null;
    }
  };

  $("#coenrollment_link").click(function(event) {
    event.preventDefault();
    var template = $(this).data('template');
    var path = $(this).data('path');
    signupDialog(template, I18n.t("parent_signup", "Parent Signup"), path);
  });
  $("#register_link").click(function(){
    $.trackPageview("/clicked_register_on_login_form");
  });

  $(".field-with-fancyplaceholder input").fancyPlaceholder();
  $("#forgot_password_form").formSubmit({
    object_name: 'pseudonym_session',
    required: ['unique_id_forgot'],
    property_validations: {
      unique_id_forgot: function(email){
        if(!loginUtils.validResetEmail(email)){
          return I18n.t("invalid_user_email", "Oops! This doesn't quite look " +
                          "like an email address, make sure you're using your " +
                          "email address affiliated with your Canvas account.");
        }
      }
    },
    beforeSubmit: function(data) {
      $(this).loadingImage();
    },
    success: function(data) {
      $(this).loadingImage('remove');
      $.flashMessage(htmlEscape(I18n.t("password_confirmation_sent", "Password confirmation sent to %{email_address}. Make sure you check your spam box.", {email_address: $(this).find(".email_address").val()})));
      $(".login_link:first").click();
    },
    error: function(data) {
      $(this).loadingImage('remove');
    }
  });
  $(".forgot_password_link").click(function(event) {
    event.preventDefault();
    $("#login_form").hide();
    $("#forgot_password_form").show();
  });
  $(".login_link").click(function(event) {
    event.preventDefault();
    $("#login_form").show();
    $("#forgot_password_form").hide();
  });

  $("#login_form")
    .submit(function(event) {
      var data = $(this).getFormData({object_name: 'pseudonym_session'});
      var success = true;
      if(!data.unique_id || data.unique_id.length < 1) {
        $(this).formErrors({
          unique_id: I18n.t("invalid_login", 'Invalid login')
        });
        success = false;
      } else if(!data.password || data.password.length < 1) {
        $(this).formErrors({
          password: I18n.t("invalid_password", 'Invalid password')
        });
        success = false;
      }
      return success;
    });

  return loginUtils;
});
