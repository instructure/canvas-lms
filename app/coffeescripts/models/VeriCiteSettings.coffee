define ['underscore'], (_) ->
  class VeriCiteSettings

    constructor: (options = {}) ->
      @originalityReportVisibility = options.originality_report_visibility || 'immediate'
      @excludeQuoted = @normalizeBoolean(options.exclude_quoted)
      @excludeSelfPlag = @normalizeBoolean(options.exclude_self_plag)
      @storeInIndex = @normalizeBoolean(options.store_in_index)
      @enableStudentPreview = @normalizeBoolean(options.enable_student_preview)
      @instEnableStudentPreview = @normalizeBoolean(options.inst_enable_student_preview)

    toJSON: =>
      originality_report_visibility: @originalityReportVisibility
      exclude_quoted: @excludeQuoted
      exclude_self_plag: @excludeSelfPlag
      store_in_index: @storeInIndex
      enable_student_preview: @enableStudentPreview
      inst_enable_student_preview: @instEnableStudentPreview

    present: =>
      json = {}
      for own key,value of this
        json[key] = value
      json

    normalizeBoolean: (value) =>
      _.contains(["1", true, "true", 1], value)
