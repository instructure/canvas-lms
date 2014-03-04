require [
  'i18n!shared.add_assignment',
  'jquery',
  'jquery.instructure_date_and_time',
  'jquery.instructure_forms',
  'jqueryui/dialog',
  'jquery.instructure_misc_plugins',
  'jquery.loadingImg'
], (I18n, $) ->

  window.attachAddAssignment = ($select, url, selector, default_name) ->
    $group = $select
    url = url or $("#add_assignment_inline_form").attr("action")
    $group.change (event) ->
      $group = $(this)
      if $(this).val() is "new"
        $("#add_assignment_inline").show().dialog(
          title: I18n.t("titles.add_assignment", "Add Assignment")
          width: 300
          height: "auto"
          autoSize: true
          modal: true
          autoOpen: false
          overlay:
            backgroundColor: "#000"
            opacity: 0.5
          open: ->
            if default_name and $.isFunction(default_name)
              name = default_name.call($group)
              $("#add_assignment_inline_form :text:first").val name
            $("#add_assignment_inline_form :text:first").focus().select()
            $("#add_assignment_inline_form").find(".weight_assignment_groups").showIf $group.hasClass("weight")
            $("#add_assignment_inline_form").data("group_select", $group).data("group_selector", selector or "").attr "action", url
          close: ->
            $group[0].selectedIndex = 0 if $group.val() is "new"
        ).dialog("open").fixDialogButtons()
    $group[0].selectedIndex = 0  if $group.val() is "new"

  $(document).ready ->
    $(".add_assignment_inline:not(:first)").remove()
    $("#add_assignment_inline_form .datetime_field").not(".datetime_field_enabled").datetime_field()
    $("#add_assignment_inline_form").formSubmit
      beforeSubmit: (data) ->
        $("#add_assignment_inline").loadingImage()
      success: (data) ->
        $("#add_assignment_inline").loadingImage "remove"
        assignment = data.assignment
        $group = $("#add_assignment_inline_form").data("group_select")
        selector = $("#add_assignment_inline_form").data("group_selector")
        $groups = $group
        $groups = $groups.add(selector)  if selector
        $groups.each ->
          $option = $(document.createElement("option"))
          $option.val(assignment.id).text assignment.title
          if $(this).children("#assignment_group_optgroup_" + assignment.assignment_group_id).length > 0
            $(this).children("#assignment_group_optgroup_" + assignment.assignment_group_id).append $option
          else
            $(this).children("option:last").before $option
        $group.val(assignment.id).change()
        $("#add_assignment_inline").dialog "close"
    $("#add_assignment_inline .cancel_button").click (event) ->
      $("#add_assignment_inline").dialog "close"