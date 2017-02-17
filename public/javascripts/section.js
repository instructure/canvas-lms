define([
  'i18n!section',
  'jquery' /* $ */,
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_date_and_time' /* time_field, datetime_field */,
  'jquery.instructure_forms' /* formSubmit, formErrors */,
  'jqueryui/dialog',
  'jquery.instructure_misc_helpers' /* replaceTags */,
  'jquery.instructure_misc_plugins' /* confirmDelete, showIf */,
  'jquery.keycodes' /* keycodes */,
  'jquery.loadingImg' /* loadingImage */,
  'jquery.templateData' /* fillTemplateData */,
  'jqueryui/autocomplete' /* /\.autocomplete/ */,
  'compiled/PaginatedList',
  'jst/courses/section/enrollment',
  'compiled/presenters/sectionEnrollmentPresenter',
  'jsx/context_cards/StudentContextCardTrigger'
], function(I18n, $, _a, _b, _c, _d, _e, _f, _g, _h, _i, _j, PaginatedList, enrollmentTemplate, sectionEnrollmentPresenter) {

  $(document).ready(function() {
    var section_id = window.location.pathname.split('/')[4],
        $edit_section_form = $("#edit_section_form"),
        $edit_section_link = $(".edit_section_link"),
        currentEnrollmentList   = new PaginatedList($('#current-enrollment-list'), {
          presenter: sectionEnrollmentPresenter,
          template: enrollmentTemplate,
          url: '/api/v1/sections/' + section_id + '/enrollments?include[]=can_be_removed'
        }),
        completedEnrollmentList = new PaginatedList($('#completed-enrollment-list'), {
          presenter: sectionEnrollmentPresenter,
          requestParams: { state: 'completed', page: 1, per_page: 25 },
          template: enrollmentTemplate,
          url: '/api/v1/sections/' + section_id + '/enrollments?include[]=can_be_removed'
        });

    $edit_section_form.formSubmit({
      beforeSubmit: function(data) {
        $edit_section_form.hide();
        $edit_section_form.find(".name").text(data['course_section[name]']).show();
        $edit_section_form.loadingImage({image_size: "small"});
      },
      success: function(data) {
        var section = data.course_section;
        $edit_section_form.loadingImage('remove');
        $('#section_name').text(section.name);
        $('span.sis_source_id').text(section.sis_source_id || "");
      },
      error: function(data) {
        $edit_section_form.loadingImage('remove');
        $edit_section_form.show();
        $edit_section_form.formErrors(data);
      }
    })
    .find(":text")
      .keycodes('return esc', function(event) {
        if(event.keyString == 'return') {
          $edit_section_form.submit();
        } else {
          $(this).parents(".section").find(".name").show();
          $edit_section_form.hide();
        }
      }).end()
    .find(".cancel_button").click(function() {
      $edit_section_form.hide();
    });

    $edit_section_link.click(function(event) {
      event.preventDefault();
      $edit_section_form.toggle();
      $("#edit_section_form :text:visible:first").focus().select();
    });

    $('.user_list').delegate('.unenroll_user_link', 'click', function(event) {
      event.preventDefault();
      $(this).parents(".user").confirmDelete({
        message: I18n.t('confirms.delete_enrollment', "Are you sure you want to delete this enrollment permanently?"),
        url: $(this).attr('href'),
        success: function() {
          $(this).slideUp(function() {
            $(this).remove();
          });
        }
      });
    });
    $(".datetime_field").datetime_field();
    $(".uncrosslist_link").click(function(event) {
      event.preventDefault();
      $("#uncrosslist_form").dialog({
        width: 400
      });
    });
    $("#uncrosslist_form .cancel_button").click(function(event) {
      $("#uncrosslist_form").dialog('close');
    }).submit(function() {
      $(this).find("button").attr('disabled', true).filter(".submit_button").text(I18n.t('status.removing_crosslisting_of_section', "De-Cross-Listing Section..."));
    });
    $(".crosslist_link").click(function(event) {
      event.preventDefault();
      $("#crosslist_course_form").dialog({
        width: 450
      });
      $("#crosslist_course_form .submit_button").attr('disabled', true);
      $("#course_autocomplete_id_lookup").val("");
      $("#course_id").val("").change();
    });
    $("#course_autocomplete_id_lookup").autocomplete({
      source: $("#course_autocomplete_url").attr('href'),
      select: function(event, ui){
        $("#course_id").val("");
        $("#crosslist_course_form").triggerHandler('id_entered', ui.item);
      }
    });
    $("#course_id").keycodes('return', function(event) {
      event.preventDefault();
      $(this).change();
    });
    $("#course_id").bind('change', function() {
      $("#course_autocomplete_id_lookup").val("");
      $("#crosslist_course_form").triggerHandler('id_entered', {id: $(this).val()});
    });
    $("#crosslist_course_form .cancel_button").click(function() {
      $("#crosslist_course_form").dialog('close');
    });
    var latest_course_id = null;
    $("#crosslist_course_form").bind('id_entered', function(event, course) {
      if(course.id == latest_course_id) { return; }
      $("#crosslist_course_form .submit_button").attr('disabled', true);
      $("#course_autocomplete_id").val("");
      if(!course.id) {
        $("#sis_id_holder,#account_name_holder").hide();
        $("#course_autocomplete_name").text("");
        return;
      }
      course.name = course.name || I18n.t('default_course_name', "Course ID \"%{course_id}\"", {course_id: course.id});
      $("#course_autocomplete_name_holder").show();
      var confirmingText = I18n.t('status.confirming_course', "Confirming %{course_name}...", {course_name: course.name});
      $("#course_autocomplete_name").text(confirmingText);
      $.screenReaderFlashMessage(confirmingText);
      $("#sis_id_holder,#account_name_holder").hide();
      $("#course_autocomplete_account_name").hide();
      var url = $.replaceTags($("#course_confirm_crosslist_url").attr('href'), 'id', course.id);
      latest_course_id = course.id;
      var course_id_before_get = latest_course_id;
      $.ajaxJSON(url, 'GET', {}, function(data) {
        if(course_id_before_get != latest_course_id) { return; }
        if(data && data.allowed) {
          var template_data = {
            sis_id: data.course && data.course.sis_source_id,
            account_name: data.account && data.account.name
          };
          $("#course_autocomplete_name_holder").fillTemplateData({data: template_data});
          $("#course_autocomplete_name").text(data.course.name);
          $.screenReaderFlashMessage(data.course.name);
          $("#sis_id_holder").showIf(template_data.sis_id);
          $("#account_name_holder").showIf(template_data.account_name);

          $("#course_autocomplete_id").val(data.course.id);
          $("#crosslist_course_form .submit_button").attr('disabled', false);
        } else {
          var errorText = I18n.t('errors.course_not_authorized_for_crosslist', "%{course_name} not authorized for cross-listing", {course_name: course.name});
          $("#course_autocomplete_name").text(errorText);
          $.screenReaderFlashError(errorText);
          $("#sis_id_holder,#account_name_holder").hide();
        }
      }, function(data) {
        $("#course_autocomplete_name").text(I18n.t('errors.confirmation_failed', "Confirmation Failed"));
      });
    });
  });
});
