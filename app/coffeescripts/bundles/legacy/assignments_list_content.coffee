require [
  "i18n!assignments.assignments_list_content",
  "jquery",
  "jquery.instructure_misc_plugins",
  "jquery.templateData",
  "vendor/date"
], (I18n, $) ->
  window.managedAssignments = null
  $(document).ready ->
    if managedAssignments
      for idx of managedAssignments
        assignment = managedAssignments[idx].assignment
        $assignment = $(".assignment_" + assignment.id)
        $assignment.fillTemplateData data:
          submitted_count: assignment.submitted_count or "0"
          graded_count: assignment.graded_count or "0"
        if assignment.submitted_count or assignment.graded_count
          $assignment.find(".submitted").showIf !!assignment.submitted_count and not assignment.graded_count
          $assignment.find(".graded").showIf !!assignment.graded_count and not assignment.submitted_count
          $assignment.find(".submitted_and_graded").showIf assignment.submitted_count and assignment.graded_count
          $assignment.find(".submitted_details").showIf !!(assignment.submitted_count or assignment.graded_count)
    if ENV.submissions_hash
      for idx of ENV.submissions_hash
        submission = ENV.submissions_hash[idx].submission
        $assignment = $(".assignment_" + idx)
        if submission and (submission.score or submission.score is 0)
          $assignment.addClass "group_assignment_graded"
          $assignment.find(".grade").show()
        else
          $assignment.removeClass "group_assignment_graded"
          $assignment.find(".grade").hide()
        if submission and submission.submission_type and not submission.score
          $assignment.addClass "group_assignment_ungraded"
          cnt = parseInt($assignment.find(".needs_grading_count").text(), 10) or 0
          cnt++
          $assignment.find(".needs_grading_count").text cnt
        $assignment.fillTemplateData
          data: submission
          hrefValues: ["assignment_id", "user_id"]
        $assignment.find(".submission_comment_link").showIf submission and submission.submission_comments_count
        $assignment.find(".rubric_assessment_link").showIf submission and submission.has_rubric_assessment
        data = $assignment.filter(":first").getTemplateData(textValues: ["due_date_string", "due_time_string"])
        due = Date.parse(data.due_date_string + " " + data.due_time_string)
        now = new Date()
        $assignment.addClass "group_assignment_submitted"  if submission and submission.submitted_at
        $assignment.addClass "group_assignment_overdue"  if due and (not submission or not submission.submitted_at) and due < now
    #.find(".more_info_link").show().end()
    $("#groups_for_student .assignment_group").find(".more_info").hide().end().find(".more_info_brief").showIf($("#group_weighting_scheme").text() is "percent").append " of final grade"
    $(".show_groups_link,.hide_groups_link").click (event) ->
      event.preventDefault()
      if $(this).hasClass("show_groups_link") and not $("#groups_for_student").hasClass("populated")
        $("#assignments_for_student .group_assignment").each ->
          $assignment = $(this).clone(true)
          group_id = $assignment.find(".assignment_group_id").text()
          $group = $("#groups_for_student .group_" + group_id)
          $group.find(".assignment_list").append $assignment
        $("#groups_for_student").addClass "populated"
      $("#groups_for_student").showIf $(this).hasClass("show_groups_link")
      $("#assignments_for_student").showIf $(this).hasClass("hide_groups_link")
      $(".show_groups_link").showIf $(this).hasClass("hide_groups_link")
      $(".hide_groups_link").showIf $(this).hasClass("show_groups_link")

    $(".group_assignment").hover (->
      if $(this).hasClass("group_assignment_overdue")
        $(this).attr "title", I18n.t("assignments.overdue", "This assignment is overdue")
      else if $(this).hasClass("group_assignment_ungraded")
        needs_grading_count = $(this).getTemplateData(textValues: ["needs_grading_count"]).needs_grading_count
        $(this).attr "title", I18n.t("assignments.needs_grading_count", "%{needs_grading_count} submissions for this assignment still need grading", { needs_grading_count: needs_grading_count })
      else $(this).attr "title", I18n.t("assignments.graded", "This assignment has been graded") if $(this).hasClass("group_assignment_graded")
    ), ->
      $(this).attr "title", ""