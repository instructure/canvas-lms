define [
  'INST'
  'i18n!user_lists'
  'jquery'
  'jquery.ajaxJSON'
  'jquery.instructure_forms'
  'jquery.instructure_misc_helpers'
  'jquery.instructure_misc_plugins'
  'jquery.loadingImg'
  'compiled/jquery.rails_flash_notifications'
  'jquery.scrollToVisible'
  'jquery.templateData'
  'vendor/jquery.scrollTo'
], (INST, I18n, $) ->

  $user_lists_processed_person_template = $("#user_lists_processed_person_template").removeAttr("id").detach()
  $user_list_no_valid_users = $("#user_list_no_valid_users")
  $user_list_with_errors = $("#user_list_with_errors")
  $user_lists_processed_people = $("#user_lists_processed_people")
  $user_list_duplicates_found = $("#user_list_duplicates_found")
  $form = $("#enroll_users_form")
  $enrollment_blank = $("#enrollment_blank").removeAttr("id").hide()
  user_lists_path = $("#user_lists_path").attr("href")

  UL = INST.UserLists =
    init: ->
      UL.showTextarea()

      $form.find(".cancel_button").click(->
        $(".add_users_link").show()
        $form.hide()
      ).end().find(".go_back_button").click(UL.showTextarea).end().find(".verify_syntax_button").click((e) ->
        e.preventDefault()
        UL.showProcessing()
        $.ajaxJSON user_lists_path, "POST", $form.getFormData(), UL.showResults
      ).end().submit (event) ->
        event.preventDefault()
        event.stopPropagation()
        $form.find(".add_users_button").text(I18n.t("adding_users", "Adding Users...")).attr "disabled", true
        $.ajaxJSON $form.attr("action"), "POST", $form.getFormData(), UL.success, UL.failure

      $form.find("#enrollment_type").change(->
        $("#limit_privileges_to_course_section_holder").showIf $(this).find(':selected').data("isAdmin")?
      ).change()

      $(".unenroll_user_link").click (event) ->
        event.preventDefault()
        event.stopPropagation()
        if $(this).hasClass("cant_unenroll")
          alert I18n.t("cant_unenroll", "This user was automatically enrolled using the campus enrollment system, so they can't be manually removed.  Please contact your system administrator if you have questions.")
        else
          $user = $(this).parents(".user")
          $sections = $(this).parents(".sections")
          $section = $(this).parents(".section")
          $toDelete = $user
          $toDelete = $section  if $sections.find(".section:visible").size() > 1
          $toDelete.confirmDelete
            message: I18n.t("delete_confirm", "Are you sure you want to remove this user?")
            url: $(this).attr("href")
            success: ->
              $(this).fadeOut ->
                UL.updateCounts()

    success: (enrollments) ->
      $form.find(".user_list").val ""
      UL.showTextarea()
      return false  if not enrollments or not enrollments.length
      already_existed = 0

      $.each enrollments, ->
        already_existed += UL.addUserToList(@enrollment)

      addedMsg = I18n.t("users_added",
        one: "1 user added"
        other: "%{count} users added"
      ,
        count: enrollments.length - already_existed
      )
      if already_existed > 0
        addedMsg += " " + I18n.t("users_existed",
          one: "(1 user already existed)"
          other: "(%{count} users already existed)"
        ,
          count: already_existed
        )
      $.flashMessage addedMsg

    failure: (data) ->
      $.flashError I18n.t("users_adding_failed", "Failed to enroll users")

    showTextarea: ->
      $form.find(".add_users_button, .go_back_button, #user_list_parsed").hide()
      $form.find(".verify_syntax_button, .cancel_button, #user_list_textarea_container").show().removeAttr "disabled"
      $form.find(".verify_syntax_button").attr("disabled", false).text I18n.t("buttons.continue", "Continue...")
      $user_list = $form.find(".user_list").removeAttr('disabled').loadingImage('remove').focus()
      $user_list.select() if $user_list.is(':visible') # .select() blows up in IE9 + jQuery 1.7.2 on invisible elements

    showProcessing: ->
      $form.find(".verify_syntax_button").attr("disabled", true).text I18n.t("messages.processing", "Processing...")
      $form.find(".user_list").attr("disabled", true).loadingImage()

    showResults: (userList) ->
      $form.find(".add_users_button, .go_back_button, #user_list_parsed").show()
      $form.find(".add_users_button").attr("disabled", false).focus().text I18n.t("add_n_users",
        one: "OK Looks Good, Add This 1 User"
        other: "OK Looks Good, Add These %{count} Users"
      ,
        count: userList.users.length
      )
      $form.find(".verify_syntax_button, .cancel_button, #user_list_textarea_container").hide()
      $form.find(".user_list").removeAttr("disabled").loadingImage "remove"
      $user_lists_processed_people.html("").show()
      if not userList or not userList.users or not userList.users.length
        $user_list_no_valid_users.appendTo $user_lists_processed_people
        $form.find(".add_users_button").hide()
      else
        if userList.errored_users and userList.errored_users.length
          $user_list_with_errors.appendTo($user_lists_processed_people).find(".message_content").text I18n.t("user_parsing_errors",
            one: "There was 1 error parsing that list of users."
            other: "There were %{count} errors parsing that list of users."
          ,
            count: userList.errored_users.length
          ) + " " + I18n.t("invalid_users_notice", "There may be some that were invalid, and you might need to go back and fix any errors.") + " " + I18n.t("users_to_add",
            one: "If you proceed as is, 1 user will be added."
            other: "If you proceed as is, %{count} users will be added."
          ,
            count: userList.users.length
          )
        if userList.duplicates and userList.duplicates.length
          $user_list_duplicates_found.appendTo($user_lists_processed_people).find(".message_content").text I18n.t("duplicate_users",
            one: "1 duplicate user found, duplicates have been removed."
            other: "%{count} duplicate user found, duplicates have been removed."
          ,
            count: userList.duplicates.length
          )
        $.each userList.users, ->
          userDiv = $user_lists_processed_person_template.clone(true).fillTemplateData(data: this).appendTo($user_lists_processed_people)
          userDiv.addClass("existing-user").attr "title", I18n.t("titles.existing_user", "Existing user")  if @user_id
          userDiv.show()

    updateCounts: ->
      $.each [ "student", "teacher", "ta", "teacher_and_ta", "student_and_observer", "observer" ], ->
        $("." + this + "_count").text $("." + this + "_enrollments .user:visible").length

    addUserToList: (enrollment) ->
      enrollmentType = $.underscore(enrollment.type)
      $list = $(".user_list." + enrollmentType + "s")
      unless $list.length
        if enrollmentType is "student_enrollment" or enrollmentType is "observer_enrollment"
          $list = $(".user_list.student_and_observer_enrollments")
        else
          $list = $(".user_list.teacher_and_ta_enrollments")
      $list.find(".none").remove()
      enrollment.invitation_sent_at = I18n.t("just_now", "Just Now")
      $before = null
      $list.find(".user").each ->
        name = $(this).getTemplateData(textValues: [ "name" ]).name
        if name and enrollment.name and name.toLowerCase() > enrollment.name.toLowerCase()
          $before = $(this)
          false

      enrollment.enrollment_id = enrollment.id
      already_existed = true
      unless $("#enrollment_" + enrollment.id).length
        already_existed = false
        $enrollment = $enrollment_blank.clone(true).fillTemplateData(
          textValues: [ "name", "membership_type", "email", "enrollment_id" ]
          id: "enrollment_" + enrollment.id
          hrefValues: [ "id", "user_id", "pseudonym_id", "communication_channel_id" ]
          data: enrollment
        ).addClass(enrollmentType).removeClass("nil_class user_").addClass("user_" + enrollment.user_id).toggleClass("pending", enrollment.workflow_state isnt "active")[(if $before then "insertBefore" else "appendTo")](($before or $list)).show().animate(
          backgroundColor: "#FFEE88"
        , 1000).animate(
          display: "block"
        , 2000).animate(
          backgroundColor: "#FFFFFF"
        , 2000, ->
          $(this).css "backgroundColor", ""
        )
        $enrollment.find(".enrollment_link").removeClass("enrollment_blank").addClass "enrollment_" + enrollment.id
        $enrollment.parents(".user_list").scrollToVisible $enrollment
      UL.updateCounts()
      if already_existed then 1 else 0

  $ UL.init
  UL
