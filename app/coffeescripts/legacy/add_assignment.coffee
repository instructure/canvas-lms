define [
  'i18n!shared.add_assignment',
  'jquery',
  'jqueryui/dialog',
  'jquery.instructure_misc_plugins', # showIf
], (I18n, $) ->

  return ($select, url, selector, default_name) ->
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
