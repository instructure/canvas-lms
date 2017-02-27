require [
  "jquery",
  "i18n!context.roster_user_usage",
  "jquery.instructure_date_and_time", # $.datetimeString
  "jquery.templateData",
  "vendor/jquery.pageless"
], ($, I18n) ->
  $ ->
    url = ENV.context_url
    $("#usage_report").pageless
      totalPages: ENV.accesses_total_pages
      url: url
      loaderMsg: I18n.t("loading_more_results", "Loading more results")
      scrape: (data) ->
        if typeof (data) is "string"
          try
            data = $.parseJSON(data)
          catch e
            data = []
        for idx of data
          $access = $("#usage_report .access.blank:first").clone(true).removeClass("blank")
          access = data[idx].asset_user_access
          $access.addClass access.asset_class_name
          $access.find('.icon').addClass access.icon
          delete access.icon
          access.readable_name = access.readable_name or access.display_name or access.asset_code
          access.last_viewed = $.datetimeString(access.last_access)
          $access.fillTemplateData data: access
          $("#usage_report table tbody").append $access.show()
        ""
