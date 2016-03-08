define ['underscore'], (_) ->
  class VeriCiteSettings

    constructor: (options = {}) ->
      @originalityReportVisibility = options.originality_report_visibility || 'immediate'
      @excludeQuoted = @normalizeBoolean(options.exclude_quoted)

    toJSON: =>
      originality_report_visibility: @originalityReportVisibility
      exclude_quoted: @excludeQuoted

    present: =>
      json = {}
      for own key,value of this
        json[key] = value
      json

    normalizeBoolean: (value) =>
      _.contains(["1", true, "true", 1], value)
