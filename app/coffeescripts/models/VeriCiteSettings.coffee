define ['underscore'], (_) ->
  class VeriCiteSettings

    constructor: (options = {}) ->
      @originalityReportVisibility = options.originality_report_visibility || 'immediate'
      @excludeQuoted = @normalizeBoolean(options.exclude_quoted)
      @excludeSelfPlag = @normalizeBoolean(options.exclude_self_plag)
      @storeInIndex = @normalizeBoolean(options.store_in_index)

    toJSON: =>
      originality_report_visibility: @originalityReportVisibility
      exclude_quoted: @excludeQuoted
      exclude_self_plag: @excludeSelfPlag
      store_in_index: @storeInIndex

    present: =>
      json = {}
      for own key,value of this
        json[key] = value
      json

    normalizeBoolean: (value) =>
      _.contains(["1", true, "true", 1], value)
