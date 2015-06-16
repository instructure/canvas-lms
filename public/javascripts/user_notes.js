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
  'i18n!user_notes',
  'jquery',
  'jquery.instructure_forms',
  'jquery.loadingImg',
  'jquery.instructure_date_and_time',
  'jquery.instructure_misc_plugins'
], function(I18n, $) {

  $(".cancel_button").click(function() {
    $("#create_entry").slideUp();
  }).end().find(":text").keycodes('esc', function() {
    $(".cancel_button").click();
  });

  $("#new_user_note_button").click(function(event) {
    event.preventDefault();
    $("#create_entry").slideDown();
    $("#add_entry_form").find(":text:first").focus().select();
  });

  $("#add_entry_form").formSubmit({
    resetForm: true,
    beforeSubmit: function(data) {
      $("#create_entry").slideUp();
      $('#proccessing').loadingImage();
      return true;
    },
    success: function(data) {
      $("#no_user_notes_message").hide();
      $(this).find('.title').val('');
      $(this).find('.note').val('');
      user_note = data.user_note;
      user_note.created_at = $.datetimeString(user_note.updated_at);
      var action = $("#add_entry_form").attr('action') + '/' + user_note.id;
      $('#proccessing').loadingImage('remove');
      $('#user_note_blank').clone(true)
        .prependTo($("#user_note_list"))
        .attr('id', 'user_note_' + user_note.id)
        .fillTemplateData({data:user_note})
        .find('.delete_user_note_link')
          .attr('href', action)
          .end()
        .find('.formatted_note')
          .html($.raw(user_note.formatted_note))
          .end()
        .slideDown();
    },
    error: function(data) {
      $('#proccessing').loadingImage('remove');
      $("#create_entry").slideDown();
    }
  });

  $(".delete_user_note_link").click(function(event) {
    event.preventDefault();
    var token = $("form:first").getFormData().authenticity_token;
    var $user_note = $(this).parents(".user_note");
    $user_note.confirmDelete({
      message: I18n.t('confirms.delete_journal_entry', "Are you sure you want to delete this journal entry?"),
      token: token,
      url: $(this).attr('href'),
      success: function() {
        $(this).fadeOut('slow', function() {
          $(this).remove();
          if (!$('#user_note_list > .user_note').length) {
            $("#no_user_notes_message").show();
          }
        });
      },
      error: function(data) {
        $(this).formErrors(data);
      }
    });
  });
});

