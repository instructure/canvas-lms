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

(function($) {

  var $email_lists_processed_person_template = $("#email_lists_processed_person_template").removeAttr('id').detach(),
      $user_emails_no_valid_emails = $("#user_emails_no_valid_emails"),
      $user_emails_with_errors = $("#user_emails_with_errors"),
      $email_lists_processed_people = $("#email_lists_processed_people"),
      $user_emails_duplicates_found = $("#user_emails_duplicates_found"),
      $form = $("#enroll_users_form"),
      $enrollment_blank = $("#enrollment_blank").removeAttr('id').hide(),
      email_lists_path = $("#email_lists_path").attr('href');

  var EL = INST.EmailLists = {

    init: function(){
      EL.showTextarea();

      $form
      .find(".cancel_button")
        .click(function() {
          $('.add_users_link').show();
          $form.hide();
        })
      .end()
      .find(".go_back_button")
        .click(EL.showTextarea)
      .end()
      .find(".verify_syntax_button")
        .click(function(e){
          e.preventDefault();
          EL.showProcessing();
          var params = {user_emails: $("#user_emails_textarea_container textarea").val().replace(/;/g, ",") };
          $.ajaxJSON(email_lists_path, 'POST', params, EL.showResults);
        })
      .end()
      .submit(function(event) {
        event.preventDefault();
        event.stopPropagation();
        $form.find(".add_users_button").text("Adding Users...").attr('disabled', true);
        var data = $form.getFormData();
        var url = $form.attr('action');
        var enrollmentTypeText = {
              student_enrollment: "Students",
              teacher_enrollment: "Teachers",
              ta_enrollment: "TAs"
            }[data.enrollment_type] || "Users";
        
        var erroredEmails = [];
        var finishedCount = 0;
        var startedCount = 0;
        var checkForFinish = function() {
          if(finishedCount == startedCount) {
            if(!erroredEmails.length) {
              $.flashMessage([finishedCount, enrollmentTypeText, "added"].join(" "));
            } else {
              successCount = finishedCount - erroredEmails.length;
              var message = [successCount, "out of", finishedCount, enrollmentTypeText, "added"].join(" ");
              message += ".  The following addresses had problems:<br/><span style='font-size:0.8em;'>" + erroredEmails.join(',') + "</span>";
              $.flashError(message, 20000);
            }
            $(document).triggerHandler('enrollment_added');
          } else {
            setTimeout(checkForFinish, 500);
          }
        };
        var users = [];
        $("#email_lists_processed_people .person").each(function() {
          var user = {};
          user.name = $.trim($(this).find(".name").text());
          user.email = $.trim($(this).find(".address").text());
          users.push(user);
        });
        startedCount = users.length;
        for(var idx in users) {
          var user = users[idx];
          data = $form.getFormData();
          data.user_emails = user.email;
          if(user.name) { 
            data.user_emails = "\"" + user.name.replace(/\"/g, "'") + "\" <" + user.email + ">";
          }
          $.ajaxJSON(url, 'POST', data, function(enrollments) {
            finishedCount += 1;
            if (!enrollments || !enrollments.length) { return false; }

            var enrollmentType = $.underscore(enrollments[0].enrollment.type),
                enrollmentTypeText = {
                  student_enrollment: "Students",
                  teacher_enrollment: "Teachers",
                  ta_enrollment: "TAs"
                }[enrollmentType] || "Users";
                
            $form.find(".user_emails").val("");
            EL.showTextarea();

            $.each( enrollments, function(){
              EL.addUserToList(this.enrollment, enrollmentType);
            });
          }, function(data) {
            finishedCount += 1;
            erroredEmails.push(user.email);
          });
        }
        setTimeout(checkForFinish, 500);
      });
      $form.find("#enrollment_type").change(function() {
        $("#limit_priveleges_to_course_section_holder").showIf($(this).val() == "TeacherEnrollment" || $(this).val() == "TaEnrollment");
      }).change();

      $(".unenroll_user_link").click(function(event) {
        event.preventDefault();
        event.stopPropagation();
        if($(this).hasClass('cant_unenroll')) {
          alert("This user was automatically enrolled using the campus enrollment system, so they can't be manually removed.  Please contact your system administrator if you have questions.");
        } else {
          $(this).parents(".user").confirmDelete({
            message: "Are you sure you want to remove this user?",
            url: $(this).attr('href'),
            success: function() {
              $(this).fadeOut(function() {
                EL.updateCounts();
              });
            }
          });
        }
      });
    },

    showTextarea: function(){
      $form.find(".add_users_button, .go_back_button, #user_emails_parsed").hide();
      $form.find(".verify_syntax_button, .cancel_button, #user_emails_textarea_container").show().removeAttr('disabled');
      $form.find(".user_emails").removeAttr('disabled').loadingImage('remove').focus().select();
      $form.find(".verify_syntax_button").attr('disabled', false).text("Continue...");
    },

    showProcessing: function(){
      $form.find(".verify_syntax_button").attr('disabled', true).text("Processing...");
      $form.find(".user_emails").attr('disabled', true).loadingImage();
    },

    showResults: function(emailList){
      $form.find(".add_users_button, .go_back_button, #user_emails_parsed").show();
      $form.find(".add_users_button").attr('disabled', false).text("OK Looks Good, Add These " + emailList.addresses.length + " Users");
      $form.find(".verify_syntax_button, .cancel_button, #user_emails_textarea_container").hide();
      $form.find(".user_emails").removeAttr('disabled').loadingImage('remove');

      $email_lists_processed_people.html("").show();

      if (!emailList || !emailList.addresses || !emailList.addresses.length) {
       $user_emails_no_valid_emails.appendTo($email_lists_processed_people);
       $form.find(".add_users_button").hide();
      }
      else {
        if (emailList.errored_addresses && emailList.errored_addresses.length) {
          $user_emails_with_errors
            .appendTo($email_lists_processed_people)
            .find('.addresses_count')
              .html(emailList.addresses.length)
              .end()
            .find('.errors_count')
              .html(emailList.errored_addresses.length);
        }
        if (emailList.duplicates && emailList.duplicates.length) {
          $user_emails_duplicates_found
            .appendTo($email_lists_processed_people)
            .find('.duplicate_count')
              .html(emailList.duplicates.length)
              .end()
            .find('.duplicates_plurality')
              .html(emailList.duplicates.length > 1 ? 'es': '');
        }

        $.each(emailList.addresses, function(){
          $email_lists_processed_person_template
            .clone(true)
            .fillTemplateData({ data: this })
            .appendTo($email_lists_processed_people)
            .show();
        });
      }
    },

    updateCounts: function() {
      $.each(['student', 'teacher', 'ta', 'teacher_and_ta', 'student_and_observer'], function(){
        $("." + this + "_count").text( $("." + this + "_enrollments .user:visible").length );
      });
    },

    addUserToList: function(enrollment, enrollmentType){
      var $list = $(".user_list." + enrollmentType + "s");
      if(!$list.length) {
        if(enrollmentType == 'student_enrollment' || enrollmentType == 'observer_enrollment') {
          $list = $(".user_list.student_and_observer_enrollments");
        } else {
          $list = $(".user_list.teacher_and_ta_enrollments");
        }
      }
      $list.find(".none").remove();
      enrollment.invitation_sent_at = "Just Now";
      try {
        enrollment.name = enrollment.user.last_name_first || enrollment.user.name;
        enrollment.pseudonym_id = enrollment.user.pseudonym.id;
        enrollment.communication_channel_id = enrollment.user.pseudonym.communication_channel.id;
      } catch(e) {}
      var $before = null;
      $list.find(".user").each(function() {
        var name = $(this).getTemplateData({textValues: ['name']}).name;
        if(name && enrollment.name && name.toLowerCase() > enrollment.name.toLowerCase()) {
          $before = $(this);
          return false;
        }
      });
      if(!$("#enrollment_" + enrollment.id).length) {
        enrollment.pseudonym_id = enrollment.users_pseudonym_id;
        var $enrollment = $enrollment_blank
          .clone(true)
          .fillTemplateData({
            textValues: ['name'],
            id: 'enrollment_' + enrollment.id,
            hrefValues: ['id', 'user_id', 'pseudonym_id', 'communication_channel_id'],
            data: enrollment
          })
          .addClass(enrollmentType)
          .removeClass('nil_class user_')
          .addClass('user_' + enrollment.user_id)
          .toggleClass('pending', enrollment.workflow_state != 'active')
          [($before ? 'insertBefore' : 'appendTo')]( ($before || $list) )
          .show()
          .animate({'backgroundColor': '#FFEE88'}, 1000)
          .animate({'display': 'block'}, 2000)
          .animate({'backgroundColor': '#FFFFFF'}, 2000, function() {
            $(this).css('backgroundColor', '');
          });
        $enrollment
          .parents(".user_list")
          .scrollToVisible($enrollment);
      }
      EL.updateCounts();
    }

  };
  
  // run the init function on domready
  $(INST.EmailLists.init);
  
})(jQuery, INST);
