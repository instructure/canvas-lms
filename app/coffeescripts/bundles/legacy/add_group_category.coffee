require [
  "i18n!groups",
  "jquery",
  "jqueryui/dialog",
  "compiled/jquery/fixDialogButtons"
], (I18n, $) ->
  window.addGroupCategory = (callback) ->
    $("#add_category_form").dialog(
      width: "auto"
      title: I18n.t("titles.add_group_category", "Add Set of Groups")
      modal: true
      overlay:
        backgroundColor: "#000"
        opacity: 0.7
    ).fixDialogButtons()
    callbacks = $("#add_category_form").data("callbacks") or []
    callbacks.push callback
    $("#add_category_form").data "callbacks", callbacks
