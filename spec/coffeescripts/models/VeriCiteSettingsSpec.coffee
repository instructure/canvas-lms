define  [
  'compiled/models/VeriCiteSettings'
], ( VeriCiteSettings ) ->

  module "VeriCiteSettings"

  module "VeriCiteSettings#constructor"

  test "assigns originalityReportVisibility", ->
    ts = new VeriCiteSettings originality_report_visibility: 'after_grading'
    strictEqual ts.originalityReportVisibility, 'after_grading'

  test "assigns excludeQuoted", ->
    ts = new VeriCiteSettings exclude_quoted: false
    strictEqual ts.excludeQuoted, false
  test "works with '0' and '1' as well", ->
    ts = new VeriCiteSettings
      exclude_quoted: '1'
    strictEqual ts.excludeQuoted, true

  module "VeriCiteSettings#toJSON"

  test "it converts back to snake_case", ->
    options =
      exclude_quoted: false
      exclude_self_plag: false
      originality_report_visibility: 'after_grading'
      store_in_index: false
    ts = new VeriCiteSettings options
    deepEqual ts.toJSON(), options

  module "VeriCiteSettings#present",
    setup: ->
      @options =
        exclude_biblio: true
        originality_report_visibility: 'after_grading'
      @ts = new VeriCiteSettings @options
      @view = @ts.present()
