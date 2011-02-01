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

$(document).ready(function() {
  var $form = $("#edit_pseudonym_form");
  var passwordable_account_ids = $("#passwordable_account_ids").text().split(",");
  $form.formSubmit({
    processData: function(data) {
      if(!$(this).hasClass('passwordable') || (!data['pseudonym[password]'] && !data['pseudonym[password_confirmation]'])) {
        delete data['pseudonym[password]'];
        delete data['pseudonym[password_confirmation]'];
      }
      if((data['pseudonym[password]'] || data['pseudonym[password_confirmation]']) && data['pseudonym[password]'] != data['pseudonym[password_confirmation]']) {
        $(this).formErrors({'pseudonym[password]': 'passwords do not match'});
        return false;
      }
    },
    beforeSubmit: function(data) {
      $(this).find("button").attr('disabled', true)
        .filter(".submit_button").text("Saving...");
      var select = $(this).find(".account_id select")[0];
      var idx = select && select.selectedIndex;
      $(this).data('account_name', null);
      $(this).data('account_name', select && select.options[idx] && select.options[idx].innerHTML);
    },
    success: function(data) {
      $(this).find("button").attr('disabled', false)
        .filter(".submit_button").text("Save");
      $(this).dialog('close');
      if($(this).data('unique_id_text')) {
        var $login = $(this).data('unique_id_text').parents(".login");
      } else {
        var $login = $("#login_information .login.blank").clone(true);
        $("#login_information .add_holder").before($login.show());
        data.pseudonym.account_name = $(this).data('account_name') || $(this).find(".default_account_name").text();
      }
      $login.fillTemplateData({
        data: data.pseudonym,
        hrefValues: ['account_id']
      });
      if($.inArray(data.pseudonym.account_id.toString(), passwordable_account_ids) != -1) {
        $login.find(".links").addClass('passwordable');
      }
      $("#login_information .login .delete_pseudonym_link").show();
    },
    error: function(data) {
      $(this).find("button").attr('disabled', false)
        .filter(".submit_button").text("Save Failed");
    }
  });
  $("#edit_pseudonym_form .account_id_select").change(function() {
    $("#edit_pseudonym_form").find("tr.password").showIf($.inArray($(this).val(), passwordable_account_ids) != -1);
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
    var $form = $("#edit_pseudonym_form");
    $form.attr('action', $(this).attr('rel')).attr('method', 'PUT');
    var data = $(this).parents(".login").getTemplateData({textValues: ['unique_id']});
    data.password = "";
    data.password_confirmation = "";
    $form.fillFormData(data, {object_name: 'pseudonym'});
    var passwordable = $(this).parents(".links").hasClass('passwordable');
    $form.toggleClass('passwordable', passwordable);
    $form.find("tr.password").showIf(passwordable);
    $form.find(".account_id").hide();
    $form.dialog('close').dialog({
      autoOpen: false,
      width: 'auto',
      close: function() {
        if($form.data('unique_id_text') && $form.data('unique_id_text').parents(".login").hasClass('blank')) {
          $form.data('unique_id_text').parents(".login").remove();
        }
      }
    }).dialog('open');
    $form.dialog('option', 'title', 'Update Login')
      .find(".submit_button").text("Update Login");
    var $unique_id = $(this).parents(".login").find(".unique_id");
    $form.data('unique_id_text', $unique_id);
    $form.find(":input:visible:first").focus().select();
  })
  .delegate('.delete_pseudonym_link', 'click', function(event) {
    event.preventDefault();
    if($("#login_information .login:visible").length < 2) {
      alert("You can't delete the last login for a user");
      return;
    }
    var login = $(this).parents(".login").find(".unique_id").text();
    $(this).parents(".login").confirmDelete({
      message: "Are you sure you want to delete the login, \"" + login + "\"?",
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
    $form.dialog('option', 'title', 'Add Login')
      .find(".submit_button").text("Add Login");
    $form.find(".account_id").show();
    $form.find(".account_id_select").change();
    $form.data('unique_id_text', null);
  });
});