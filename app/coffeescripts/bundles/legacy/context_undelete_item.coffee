require [
  "jquery",
  "i18n!context.undelete_index",
  "jquery.ajaxJSON",
  "jquery.instructure_misc_plugins"
], ($, I18n) ->
  $(document).ready ->
    $(".restore_link").click (event) ->
      event.preventDefault()
      $link = $(this)
      $item = $link.parents(".item")
      item_name = $.trim($item.find(".name").text())
      result = confirm(I18n.t("are_you_sure","Are you sure you want to restore %{item_name}?", item_name: item_name))
      if result
        $link.text I18n.t("restoring", "restoring...")
        $item.dim()
        $.ajaxJSON $link.attr("href"), "POST", {}, (->
          $item.slideUp ->
            $item.remove()
        ), ->
          $link.text I18n.t("restore_failed", "restore failed")