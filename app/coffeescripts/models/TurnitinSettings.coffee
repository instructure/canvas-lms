define [], ->
  class TurnitinSettings

    constructor: (options = {}) ->
      @sPaperCheck = options.s_paper_check || false
      @originalityReportVisibility = options.originality_report_visibility ||
        false
      @internetCheck = options.internet_check || false
      @excludeBiblio = options.exclude_biblio || false
      @excludeQuoted = options.exclude_quoted || false
      @journalCheck = options.journal_check || false
      @excludeSmallMatchesType = options.exclude_small_matches_type
      @excludeSmallMatchesValue = options.exclude_small_matches_value || 0

    words: =>
      if @excludeSmallMatchesType == 'percent' then "" else @excludeSmallMatchesValue

    percent: =>
      if @excludeSmallMatchesType == 'words' then "" else @excludeSmallMatchesValue

    toJSON: =>
      s_paper_check: @sPaperCheck
      originality_report_visibility: @originalityReportVisibility
      internet_check: @internetCheck
      exclude_biblio: @excludeBiblio
      exclude_quoted: @excludeQuoted
      journal_check: @journalCheck
      exclude_small_matches_type: @excludeSmallMatchesType
      exclude_small_matches_value: @excludeSmallMatchesValue

    excludesSmallMatches: =>
      !!@excludeSmallMatchesType?

    toView: =>
      viewJSON = {}
      for own key,value of this
        viewJSON[key] = value
      viewJSON.excludesSmallMatches = @excludesSmallMatches()
      viewJSON.words = @words()
      viewJSON.percent = @percent()
      viewJSON
