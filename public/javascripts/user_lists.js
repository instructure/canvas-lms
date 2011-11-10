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

require([
  'INST' /* INST */,
  'i18n!user_lists',
  'jquery' /* $ */,
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_forms' /* getFormData */,
  'jquery.instructure_misc_helpers' /* /\$\.underscore/ */,
  'jquery.instructure_misc_plugins' /* confirmDelete, showIf */,
  'jquery.loadingImg' /* loadingImg, loadingImage */,
  'jquery.rails_flash_notifications' /* flashMessage, flashError */,
  'jquery.scrollToVisible' /* scrollToVisible */,
  'jquery.templateData' /* fillTemplateData, getTemplateData */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */
], function(INST, I18n, $) {

  var $user_lists_processed_person_template = $("#user_lists_processed_person_template").removeAttr('id').detach(),
      $user_list_no_valid_users = $("#user_list_no_valid_users"),
      $user_list_with_errors = $("#user_list_with_errors"),
      $user_lists_processed_people = $("#user_lists_processed_people"),
      $user_list_duplicates_found = $("#user_list_duplicates_found"),
      $form = $("#enroll_users_form"),
      $enrollment_blank = $("#enrollment_blank").removeAttr('id').hide(),
      user_lists_path = $("#user_lists_path").attr('href');

  var UL = INST.UserLists = {

    init: function(){
      UL.showTextarea();

      $form
      .find(".cancel_button")
        .click(function() {
          $('.add_users_link').show();
          $form.hide();
        })
      .end()
      .find(".go_back_button")
        .click(UL.showTextarea)
      .end()
      .find(".verify_syntax_button")
        .click(function(e){
          e.preventDefault();
          UL.showProcessing();
          $.ajaxJSON(user_lists_path, 'POST', $form.getFormData(), UL.showResults);
        })
      .end()
      .submit(function(event) {
        event.preventDefault();
        event.stopPropagation();
        $form.find(".add_users_button").text(I18n.t("adding_users", "Adding Users...")).attr('disabled', true);
        $.ajaxJSON($form.attr('action'), 'POST', $form.getFormData(), function(enrollments) {
          $form.find(".user_list").val("");
          UL.showTextarea();
          if (!enrollments || !enrollments.length) { return false; }
          $.each( enrollments, function(){
            UL.addUserToList(this.enrollment);
          });
          $.flashMessage(I18n.t("users_added", { one: "1 user added", other: "%{count} users added" }, { count: enrollments.length }));
        }, function(data) {
          $.flashError(I18n.t("users_adding_failed", "Failed to enroll users"));
        });
      });
      $form.find("#enrollment_type").change(function() {
        $("#limit_privileges_to_course_section_holder").showIf($(this).val() == "TeacherEnrollment" || $(this).val() == "TaEnrollment");
      }).change();

      $(".unenroll_user_link").click(function(event) {
        event.preventDefault();
        event.stopPropagation();
        if($(this).hasClass('cant_unenroll')) {
          alert(I18n.t("cant_unenroll", "This user was automatically enrolled using the campus enrollment system, so they can't be manually removed.  Please contact your system administrator if you have questions."));
        } else {
          $(this).parents(".user").confirmDelete({
            message: I18n.t("delete_confirm", "Are you sure you want to remove this user?"),
            url: $(this).attr('href'),
            success: function() {
              $(this).fadeOut(function() {
                UL.updateCounts();
              });
            }
          });
        }
      });
    },

    showTextarea: function(){
      $form.find(".add_users_button, .go_back_button, #user_list_parsed").hide();
      $form.find(".verify_syntax_button, .cancel_button, #user_list_textarea_container").show().removeAttr('disabled');
      $form.find(".user_list").removeAttr('disabled').loadingImage('remove').focus().select();
      $form.find(".verify_syntax_button").attr('disabled', false).text(I18n.t('buttons.continue', "Continue..."));
    },

    showProcessing: function(){
      $form.find(".verify_syntax_button").attr('disabled', true).text(I18n.t('messages.processing', "Processing..."));
      $form.find(".user_list").attr('disabled', true).loadingImage();
    },

    showResults: function(userList){
      $form.find(".add_users_button, .go_back_button, #user_list_parsed").show();
      $form.find(".add_users_button").attr('disabled', false).text(I18n.t("add_n_users", {one: "OK Looks Good, Add This 1 User", other: "OK Looks Good, Add These %{count} Users"}, {count: userList.users.length}));
      $form.find(".verify_syntax_button, .cancel_button, #user_list_textarea_container").hide();
      $form.find(".user_list").removeAttr('disabled').loadingImage('remove');

      $user_lists_processed_people.html("").show();

      if (!userList || !userList.users || !userList.users.length) {
       $user_list_no_valid_users.appendTo($user_lists_processed_people);
       $form.find(".add_users_button").hide();
      }
      else {
        if (userList.errored_users && userList.errored_users.length) {
          $user_list_with_errors
            .appendTo($user_lists_processed_people)
            .find('.message_content')
              .html(I18n.t("user_parsing_errors", { one: "There was 1 error parsing that list of users.", other: "There were %{count} errors parsing that list of users."}, {count:userList.errored_users.length}) + " " + I18n.t("invalid_users_notice", "There may be some that were invalid, and you might need to go back and fix any errors.") + " " + I18n.t("users_to_add", { one: "If you proceed as is, 1 user will be added.", other: "If you proceed as is, %{count} users will be added." }, {count: userList.users.length}));
        }
        if (userList.duplicates && userList.duplicates.length) {
          $user_list_duplicates_found
            .appendTo($user_lists_processed_people)
            .find('.message_content')
              .html(I18n.t("duplicate_users", { one: "1 duplicate user found, duplicates have been removed.", other: "%{count} duplicate user found, duplicates have been removed."}, {count:userList.duplicates.length}))
        }

        $.each(userList.users, function(){
          $user_lists_processed_person_template
            .clone(true)
            .fillTemplateData({ data: this })
            .appendTo($user_lists_processed_people)
            .show();
        });
      }
    },

    updateCounts: function() {
      $.each(['student', 'teacher', 'ta', 'teacher_and_ta', 'student_and_observer', 'observer'], function(){
        $("." + this + "_count").text( $("." + this + "_enrollments .user:visible").length );
      });
    },

    addUserToList: function(enrollment){
      var enrollmentType = $.underscore(enrollment.type);
      var $list = $(".user_list." + enrollmentType + "s");
      if(!$list.length) {
        if(enrollmentType == 'student_enrollment' || enrollmentType == 'observer_enrollment') {
          $list = $(".user_list.student_and_observer_enrollments");
        } else {
          $list = $(".user_list.teacher_and_ta_enrollments");
        }
      }
      $list.find(".none").remove();
      enrollment.invitation_sent_at = I18n.t("just_now", "Just Now");
      var $before = null;
      $list.find(".user").each(function() {
        var name = $(this).getTemplateData({textValues: ['name']}).name;
        if(name && enrollment.name && name.toLowerCase() > enrollment.name.toLowerCase()) {
          $before = $(this);
          return false;
        }
      });
      if(!$("#enrollment_" + enrollment.id).length) {
        var $enrollment = $enrollment_blank
          .clone(true)
          .fillTemplateData({
            textValues: ['name', 'membership_type', 'email'],
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
      UL.updateCounts();
    }

  };
  
  // run the init function on domready
  $(INST.UserLists.init);
  
});
