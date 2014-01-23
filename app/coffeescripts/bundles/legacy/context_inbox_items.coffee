require [
  "jquery",
  "i18n!context.inbox_items",
  "jquery.instructure_misc_helpers",
  "jquery.instructure_misc_plugins",
  "jquery.templateData",
  "vendor/jquery.pageless"
], ($, I18n) ->
  $ ->
    $(".delete_inbox_item_link").click (event) ->
      event.preventDefault()
      $item = $(this).parents(".communication_message")
      $item.confirmDelete
        noMessage: true
        message: I18n.t("inbox_delete_confirm", "Are you sure you want to delete this item from your inbox?")
        url: $(this).attr("href")
        success: ->
          unless $(this).hasClass("read")
            unread = parseInt($("#identity .unread-messages-count").text(), 10) or 0
            unread--
            if unread <= 0
              $("#identity .unread-messages-count").remove()
            else
              $("#identity .unread-messages-count").text unread
          $(this).slideUp ->
            $(this).remove()

    $(".reply_inbox_item_link").click (event) ->
      event.preventDefault()
      event.stopPropagation()
      $(this).parents(".inbox_item").find(".inbox_item_link").triggerHandler "click", true

    $(".inbox_item .content").click (event) ->
      $(this).parents(".inbox_item").find(".inbox_item_link").click()

    $(".inbox_item_link").bind "click", (event, reply) ->
      event.preventDefault()
      $item = $(this).parents(".inbox_item")
      id = $item.attr("id").replace("inbox_item_", "")
      asset_type = $item.getTemplateData(textValues: ["asset_type"]).asset_type
      url = $item.find(".inbox_item_url").attr("href")
      location.href = url

    url = ENV.discussion_replies_path
    $("#message_list").pageless
      totalPages: ENV.total_pages
      url: url
      params:
        view: $.queryParam("view")

      loaderMsg: I18n.t("loading_results", "Loading more results")
      scrape: (data) ->
        if typeof (data) is "string"
          try
            data = $.parseJSON(data)
          catch e
            data = []
        for idx of data
          $item = messages.updateInboxItem(null, data[idx])
        ""