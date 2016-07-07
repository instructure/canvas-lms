/**
 * Copyright (C) 2011 Instructure, Inc.
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
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

define([
  'i18n!user_logins',
  'jquery' /* $ */,
  'compiled/models/Pseudonym',
  'jquery.instructure_forms' /* formSubmit, fillFormData, formErrors */,
  'jqueryui/dialog',
  'compiled/jquery/fixDialogButtons' /* fix dialog formatting */,
  'jquery.instructure_misc_plugins' /* confirmDelete, showIf */,
  'jquery.templateData' /* fillTemplateData, getTemplateData */
], function(I18n, $, Pseudonym) {
$(document).ready(function() {
  var $form = $("#edit_pseudonym_form");
  $form.formSubmit({
    disableWhileLoading: true,
    formErrors: false,
    processData: function(data) {
      if(!$(this).hasClass('passwordable') || (!data['pseudonym[password]'] && !data['pseudonym[password_confirmation]'])) {
        delete data['pseudonym[password]'];
        delete data['pseudonym[password_confirmation]'];
      }
    },
    beforeSubmit: function(data) {
      var select = $(this).find(".account_id select")[0];
      var idx = select && select.selectedIndex;
      $(this).data('account_name', null);
      $(this).data('account_name', select && select.options[idx] && select.options[idx].innerHTML);
    },
    success: function(data) {
      $(this).dialog('close');
      if($(this).data('unique_id_text')) {
        var $login = $(this).data('unique_id_text').parents(".login");
      } else {
        var $login = $("#login_information .login.blank").clone(true);
        $("#login_information .add_holder").before($login);
        $login.removeClass('blank');
        $login.show();
        data.account_name = $(this).data('account_name');
      }
      $login.fillTemplateData({
        data: data,
        hrefValues: ['id', 'account_id']
      });
      $login.find(".links").addClass('passwordable');
      $("#login_information .login .delete_pseudonym_link").show();
			$.flashMessage(I18n.t('save_succeeded', 'Save successful'));
    },
    error: function(errors, jqXHR, response) {
      if (response.status === 401) return $.flashError(I18n.t('error.unauthorized', "You do not have sufficient privileges to make the change requested"));
      var accountId = $(this).find(".account_id select").val();
      var policy = ENV.PASSWORD_POLICIES && ENV.PASSWORD_POLICIES[accountId] || ENV.PASSWORD_POLICY;
      errors = Pseudonym.prototype.normalizeErrors(errors, policy);
      $(this).formErrors(errors);
    }
  });
  $("#edit_pseudonym_form .cancel_button").click(function() {
    $form.dialog('close');
  });
  $("#login_information").delegate('.login_details_link', 'click', function(event) {
    event.preventDefault();
    $(this).parents("tr").find(".login_details").show();
    $(this).hide();
  })
  .delegate('.edit_pseudonym_link', 'click', function(event) {
    event.preventDefault();
    var $form = $("#edit_pseudonym_form"),
        $sis_row = $form.find('.sis_user_id'),
        $integration_id_row = $form.find('.integration_id');
    $sis_row.hide();
    $integration_id_row.hide();
    $form.attr('action', $(this).attr('rel')).attr('method', 'PUT');
    var data = $(this).parents(".login").getTemplateData({textValues: ['unique_id', 'sis_user_id', 'integration_id', 'can_edit_sis_user_id']});
    data.password = "";
    data.password_confirmation = "";
    $form.fillFormData(data, {object_name: 'pseudonym'});
    if( data.can_edit_sis_user_id == 'true' ){
      $sis_row.show();
      $integration_id_row.show();
    } else {
      $sis_row.remove();
      $integration_id_row.remove();
    }
    var passwordable = $(this).parents(".links").hasClass('passwordable');
    var delegated = passwordable && $(this).parents(".links").hasClass('delegated-auth');
    $form.toggleClass('passwordable', passwordable);
    $form.find("tr.password").showIf(passwordable);
    $form.find("tr.delegated").showIf(delegated);
    $form.find(".account_id").hide();
    var $account_select = $form.find(".account_id select");
    var accountId = $(this).data("accountId");
    if( $account_select && accountId ){
      $account_select.val(accountId);
    }
    $form.dialog({
      width: 'auto',
      close: function() {
        if($form.data('unique_id_text') && $form.data('unique_id_text').parents(".login").hasClass('blank')) {
          $form.data('unique_id_text').parents(".login").remove();
        }
      }
    });
    $form.dialog('option', 'title', I18n.t('titles.update_login', 'Update Login'))
      .find(".submit_button").text(I18n.t('buttons.update_login', "Update Login"));
    $form.dialog('option', 'beforeClose', function(){
      $('.error_box:visible').click();
    })
    var $unique_id = $(this).parents(".login").find(".unique_id");
    $form.data('unique_id_text', $unique_id);
    $form.find(":input:visible:first").focus().select();
  })
  .delegate('.delete_pseudonym_link', 'click', function(event) {
    event.preventDefault();
    if($("#login_information .login:visible").length < 2) {
      alert(I18n.t('notices.cant_delete_last_login', "You can't delete the last login for a user"));
      return;
    }
    var login = $(this).parents(".login").find(".unique_id").text();
    $(this).parents(".login").confirmDelete({
      message: I18n.t('confirms.delete_login', "Are you sure you want to delete the login, \"%{login}\"?", {login: login}),
      url: $(this).attr('rel'),
      success: function() {
        $(this).fadeOut();
        if($("#login_information .login:visible").length < 2) {
          $("#login_information .login .delete_pseudonym_link").hide();
        }
      }
    });
  })
  .delegate('.add_pseudonym_link', 'click', function(event) {
    event.preventDefault();
    $("#login_information .login.blank .edit_pseudonym_link").click();
    $form.attr('action', $(this).attr('rel')).attr('method', 'POST');
    $form.fillFormData({'pseudonym[unique_id]': ''});
    $form.dialog('option', 'title', I18n.t('titles.add_login', 'Add Login'))
      .find(".submit_button").text(I18n.t('buttons.add_login', "Add Login"));
    $form.addClass('passwordable');
    $form.find("tr.password").show();
    $form.find(".account_id").show();
    $form.find(".account_id_select").change();
    $form.data('unique_id_text', null);
  });

  $(".reset_mfa_link").click(function(event) {
    var $disable_mfa_link = $(this);
    $.ajaxJSON($disable_mfa_link.attr('href'), 'DELETE', null, function() {
      $.flashMessage(I18n.t('notices.mfa_reset', "Multi-factor authentication reset"));
      $disable_mfa_link.parent().remove();
    });
    event.preventDefault();
  });
});
});
