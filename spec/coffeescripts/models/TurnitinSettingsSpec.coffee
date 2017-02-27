define  [
  'compiled/models/TurnitinSettings'
], ( TurnitinSettings ) ->

  QUnit.module "TurnitinSettings"

  QUnit.module "TurnitinSettings#constructor"

  test "assigns originalityReportVisibility", ->
    ts = new TurnitinSettings originality_report_visibility: 'after_grading'
    strictEqual ts.originalityReportVisibility, 'after_grading'

  test "assigns sPaperCheck", ->
    ts = new TurnitinSettings s_paper_check: true
    strictEqual ts.sPaperCheck, true

  test "assigns internetCheck", ->
    ts = new TurnitinSettings internet_check: true
    strictEqual ts.internetCheck, true

  test "assigns excludeBiblio", ->
    ts = new TurnitinSettings exclude_biblio: false
    strictEqual ts.excludeBiblio, false

  test "assigns excludeQuoted", ->
    ts = new TurnitinSettings exclude_quoted: false
    strictEqual ts.excludeQuoted, false

  test "assigns journalCheck", ->
    ts = new TurnitinSettings journal_check: true
    strictEqual ts.journalCheck, true

  test "works with '0' and '1' as well", ->
    ts = new TurnitinSettings
      s_paper_check: '0'
      internet_check: '1'
      exclude_biblio: '0'
      exclude_quoted: '1'
      journal_check: '0'
    strictEqual ts.sPaperCheck, false
    strictEqual ts.internetCheck, true
    strictEqual ts.excludeBiblio, false
    strictEqual ts.excludeQuoted, true
    strictEqual ts.journalCheck, false

  test "assigns excludeSmallMatchesType", ->
    ts = new TurnitinSettings exclude_small_matches_type: 'words'
    strictEqual ts.excludeSmallMatchesType, 'words'

  test "assigns excludeSmallMatchesValue", ->
    ts = new TurnitinSettings exclude_small_matches_value: 100
    strictEqual ts.excludeSmallMatchesValue, 100

  test "assigns correct percent", ->
    ts = new TurnitinSettings
      exclude_small_matches_type: 'words'
      exclude_small_matches_value: 100
    strictEqual ts.percent(), ""
    ts = new TurnitinSettings
      exclude_small_matches_type: 'percent'
      exclude_small_matches_value: 100
    strictEqual ts.percent(), 100

  test "assigns correct words", ->
    ts = new TurnitinSettings
      exclude_small_matches_type: 'words'
      exclude_small_matches_value: 100
    strictEqual ts.words(), 100
    ts = new TurnitinSettings
      exclude_small_matches_type: 'percent'
      exclude_small_matches_value: 100
    strictEqual ts.words(), ""

  QUnit.module "TurnitinSettings#toJSON"

  test "it converts back to snake_case", ->
    options =
      exclude_small_matches_value: 100
      exclude_small_matches_type: 'words'
      journal_check: false
      exclude_quoted: false
      exclude_biblio: true
      internet_check: true
      originality_report_visibility: 'after_grading'
      s_paper_check: true
      submit_papers_to: false
    ts = new TurnitinSettings options
    deepEqual ts.toJSON(), options

  QUnit.module "TurnitinSettings#excludesSmallMatches"

  test "returns true when excludeSmallMatchesType is not null", ->
    ts = new TurnitinSettings exclude_small_matches_type: 'words'
    strictEqual ts.excludesSmallMatches(), true

  test "returns false when excludeSmallMatchesType is null", ->
    ts = new TurnitinSettings exclude_small_matches_type: null
    strictEqual ts.excludesSmallMatches(), false

  QUnit.module "TurnitinSettings#present",
    setup: ->
      @options =
        exclude_small_matches_value: 100
        exclude_small_matches_type: 'words'
        journal_check: false
        exclude_quoted: false
        exclude_biblio: true
        internet_check: true
        originality_report_visibility: 'after_grading'
        s_paper_check: true
      @ts = new TurnitinSettings @options
      @view = @ts.present()

  test "includes excludesSmallMatches", ->
    strictEqual @view.excludesSmallMatches, @ts.excludesSmallMatches()

  test "includes all the default fields", ->
    for own key,value of @view when key != 'excludesSmallMatches' && key != 'words' && key != 'percent'
      strictEqual value, @ts[ key ]
