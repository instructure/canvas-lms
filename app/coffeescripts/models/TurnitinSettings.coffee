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
      @submitPapersTo =
        if options.hasOwnProperty('submit_papers_to') then options.submit_papers_to else true

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
