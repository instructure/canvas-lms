define ['underscore'], (_) ->
  class TurnitinSettings

    constructor: (options = {}) ->
      @originalityReportVisibility = options.originality_report_visibility || 'immediate'
      @sPaperCheck = @normalizeBoolean(options.s_paper_check)
      @internetCheck = @normalizeBoolean(options.internet_check)
      @excludeBiblio = @normalizeBoolean(options.exclude_biblio)
      @excludeQuoted = @normalizeBoolean(options.exclude_quoted)
      @journalCheck = @normalizeBoolean(options.journal_check)
      @excludeSmallMatchesType = options.exclude_small_matches_type
      @excludeSmallMatchesValue = options.exclude_small_matches_value || 0
      @submitPapersTo =
        if options.hasOwnProperty('submit_papers_to') then @normalizeBoolean(options.submit_papers_to) else true

    words: =>
      if @excludeSmallMatchesType == 'words' then @excludeSmallMatchesValue else ""

    percent: =>
      if @excludeSmallMatchesType == 'percent' then @excludeSmallMatchesValue else ""

    toJSON: =>
      s_paper_check: @sPaperCheck
      originality_report_visibility: @originalityReportVisibility
      internet_check: @internetCheck
      exclude_biblio: @excludeBiblio
      exclude_quoted: @excludeQuoted
      journal_check: @journalCheck
      exclude_small_matches_type: @excludeSmallMatchesType
      exclude_small_matches_value: @excludeSmallMatchesValue
      submit_papers_to: @submitPapersTo

    excludesSmallMatches: =>
      !!@excludeSmallMatchesType?

    present: =>
      json = {}
      for own key,value of this
        json[key] = value
      json.excludesSmallMatches = @excludesSmallMatches()
      json.words = @words()
      json.percent = @percent()
      json

    normalizeBoolean: (value) =>
      _.contains(["1", true, "true", 1], value)
