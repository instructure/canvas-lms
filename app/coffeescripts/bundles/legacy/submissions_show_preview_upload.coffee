require [
  "jquery",
  "i18n!submissions.show_preview",
  "vendor/swfobject/swfobject",
  "jqueryui/dialog",
  "jquery.doc_previews"
], ($, I18n, swfobject, _docPreviews) ->
  $(document).ready ->
    $("a.flash").click ->
      swfobject.embedSWF $(this).attr("href"), "main", "100%", "100%", "9.0.0", false, null,
        wmode: "opaque"
      , null
      false

    if $.filePreviewsEnabled()
      $(".modal_preview_link").live "click", ->
        #overflow:hidden is because of some weird thing where the google doc preview gets double scrollbars
        $("<div style=\"padding:0; overflow:hidden;\">").dialog(
          title: I18n.t("preview_title", "Preview of %{title}", { title: $(this).data("dialog-title") })
          width: $(document).width() * .95
          height: $(document).height() * .75
        ).loadDocPreview $.extend(
          height: "100%"
        , $(this).data())
        false