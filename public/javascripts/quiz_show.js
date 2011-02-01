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

$(document).ready(function () {
  $(".delete_quiz_link").click(function(event) {
    event.preventDefault();
    $("nothing").confirmDelete({
      url: $(this).attr('href'),
      message: "Are you sure you want to delete this quiz?",
      success: function() {
        window.location.href = $('#context_quizzes_url').attr('href');
      }
    });
  });
  $(".quiz_details_link").click(function(event) {
    event.preventDefault();
    $("#quiz_details").slideToggle();
  });
  $(".message_students_link").click(function(event) {
    event.preventDefault();
    
    var students_hash = {};
    var title = $("#quiz_title").text();
    $(".student_list .student").each(function(i) {
      var student = {};
      student.id = $(this).attr('data-id');
      student.name = $.trim($(this).find(".name").text());
      student.submitted = $(this).closest(".student_list").hasClass('submitted');
      students_hash[student.id] = student;
    });
    var students = [];
    for(var idx in students_hash) {
      students.push(students_hash[idx]);
    }
    
    window.messageStudents({
      options: [
        {text: "Have taken the quiz"},
        {text: "Have NOT taken the quiz"}
      ],
      title: title,
      students: students,
      callback: function(selected, cutoff, students) {
        students = $.grep(students, function($student, idx) {
          var student = $student.user_data;
          if(selected == "Have taken the quiz") {
            return student.submitted;
          } else if(selected == "Have NOT taken the quiz") {
            return !student.submitted;
          }
        });
        return $.map(students, function(student) { return student.user_data.id; });
      }
    });
  });
  $.scrollSidebar();
  
  $("#let_students_take_this_quiz_button").ifExists(function($link){
    var $unlock_for_how_long_dialog = $("#unlock_for_how_long_dialog");

    $link.click(function(){
      $unlock_for_how_long_dialog.dialog('open');
      return false;
    });
    
    $unlock_for_how_long_dialog.dialog({
      autoOpen: false,
      modal: true,
      resizable: false,
      width: 400,
      buttons: {
        'Unlock' : function(){
          var dateString = $(this).find('.datetime_suggest').text();

          $link.closest('form')
            // append this back to the form since it got moved to be a child of body when we called .dialog('open')
            .append($(this).dialog('destroy'))
            .find('#quiz_lock_at')
              .val(dateString).end()
            .submit();
        }
      }
    }).find('.datetime_field').datetime_field();
  });

});
