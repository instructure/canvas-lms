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
  'i18n!question_banks',
  'jquery' /* $ */,
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_date_and_time' /* datetimeString */,
  'jquery.instructure_forms' /* formSubmit, fillFormData, formErrors */,
  'jquery.instructure_misc_plugins' /* confirmDelete */,
  'jquery.keycodes' /* keycodes */,
  'jquery.loadingImg' /* loadingImage */,
  'jquery.templateData' /* fillTemplateData, getTemplateData */
], function(I18n, $) {

$(document).ready(function() {
  $(".add_bank_link").click(function(event) {
    event.preventDefault();
    var $bank = $("#question_bank_blank").clone(true).attr('id', 'question_bank_new');
    $("#questions").prepend($bank.show());
    $bank.find(".edit_bank_link").click();
  });
  $(".question_bank .delete_bank_link").click(function(event) {
    event.preventDefault();
    $(this).parents(".question_bank").confirmDelete({
      url: $(this).attr('href'),
      message: I18n.t("delete_question_bank_prompt", "Are you sure you want to delete this bank of questions?"),
      success: function() {
        $(this).slideUp(function() {
          $(this).remove();
        });
      }
    });
  });
  $(".question_bank .bookmark_bank_link").click(function(event) {
    event.preventDefault();
    var $link = $(this);
    var $bank = $link.parents(".question_bank");
    $.ajaxJSON($(this).attr('href'), 'POST', {}, function(data) {
      $bank.find(".bookmark_bank_link").toggle();
    });
  });
  $(".question_bank .edit_bank_link").click(function(event) {
    event.preventDefault();
    var $bank = $(this).parents(".question_bank");
    var data = $bank.getTemplateData({textValues: ['title']});
    $bank.find(".header_content").hide();
    var $form = $("#edit_bank_form");
    $bank.find(".header").prepend($form.show());
    $form.attr('action', $(this).attr('href'));
    $form.attr('method', 'PUT');
    if($bank.attr('id') == 'question_bank_new') {
      $form.attr('action', $("#bank_urls .add_bank_url").attr('href'));
      $form.attr('method', 'POST');
    }
    $form.fillFormData(data, {object_name: 'assessment_question_bank'});
    $form.find(":text:visible:first").focus().select();
  });
  $("#edit_bank_form .bank_name_box").keycodes('return esc', function(event) {
    if(event.keyString == 'esc') {
      $(this).parents(".question_bank").addClass('dont_save')
      $(this).blur();
    } else if(event.keyString == 'return') {
      $("#edit_bank_form").submit();
    }
  });
  $("#edit_bank_form .bank_name_box").blur(function() {
    var $bank = $(this).parents(".question_bank");
    if(!$bank.hasClass('dont_save') && !$bank.hasClass('save_in_progress') && $bank.attr('id') != 'question_bank_new') {
      $("#edit_bank_form").submit();
      return;
    }
    $bank.removeClass('dont_save');
    $bank.find(".header_content").show();
    $("body").append($("#edit_bank_form").hide());
    if($bank.attr('id') == 'question_bank_new') {
      $bank.remove();
    }
  });
  $("#edit_bank_form").formSubmit({
    object_name: 'assessment_question_bank',
    beforeSubmit: function(data) {
      var $bank = $(this).parents(".question_bank");
      $bank.attr('id', 'question_bank_adding');
      try {
        $bank.addClass('save_in_progress')
        $bank.find(".bank_name_box").blur();
      } catch(e) { }
      $bank.fillTemplateData({
        data: data
      });
      $bank.loadingImage();
      return $bank;
    },
    success: function(data, $bank) {
      $bank.loadingImage('remove');
      $bank.removeClass('save_in_progress')
      var bank = data.assessment_question_bank;
      bank.last_updated_at = $.datetimeString(bank.updated_at);
      $bank.fillTemplateData({
        data: bank,
        hrefValues: ['id']
      })
    },
    error: function(data, $bank) {
      $bank.loadingImage('remove');
      $bank.removeClass('save_in_progress')
      $bank.find(".edit_bank_link").click();
      $("#edit_bank_form").formErrors(data);
    }
  });
});
});
