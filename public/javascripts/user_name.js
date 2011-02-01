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
  $("#name_and_email").delegate('.edit_user_link', 'click', function(event) {
    event.preventDefault();
    $("#edit_student_dialog").dialog('close').dialog({
      autoOpen: false,
      title: "Edit Student Details",
      width: 450
    }).dialog('open');
    $("#edit_student_form :text:visible:first").focus().select();
  });
  $("#edit_student_form").formSubmit({
    beforeSubmit: function(data) {
      $(this).find("button").attr('disabled', true)
        .filter(".submit_button").text("Updating Student...");
    },
    success: function(data) {
      $(this).find("button").attr('disabled', false)
        .filter(".submit_button").text("Update Student");
      $("#name_and_email .user_details").fillTemplateData({data: data && data.user});
      $("#edit_student_dialog").dialog('close');
    },
    error: function(data) {
      $(this).find("button").attr('disabled', false)
        .filter(".submit_button").text("Updating Student Failed, please try again");
    }
  });
  $("#edit_student_dialog .cancel_button").click(function() {
    $("#edit_student_dialog").dialog('close');
  });
  $(".remove_avatar_picture_link").click(function(event) {
    event.preventDefault();
    var $link = $(this);
    var result = confirm("Are you sure you want to remove this user's profile picture?");
    if(!result) { return; }
    $link.text("Removing image...");
    $.ajaxJSON($link.attr('href'), 'PUT', {'avatar[state]': 'none'}, function(data) {
      $link.parents("tr").find(".avatar_image").remove();
      $link.remove();
    }, function(data) {
      $link.text("Failed to remove the image, please try again");
    });
  });
  $(".report_avatar_picture_link").click(function(event) {
    event.preventDefault();
    event.preventDefault();
    var $link = $(this);
    $link.text("Reporting image...");
    $.ajaxJSON($link.attr('href'), 'POST', {}, function(data) {
      $link.after("This image has been reported");
      $link.remove();
    }, function(data) {
      $link.text("Failed to report the image, please try again");
    });
  });
});