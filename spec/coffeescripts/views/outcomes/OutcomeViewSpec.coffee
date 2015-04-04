define [
  'jquery'
  'Backbone'
  'compiled/models/Outcome'
  'compiled/views/outcomes/OutcomeView'
], ($, Backbone, Outcome, OutcomeView) ->

  fixtures = $('#fixtures')

  newOutcome = (options) ->
    new Outcome(buildOutcome(options), { parse: true })

  outcome1 = ->
    new Outcome(buildOutcome1(), { parse: true })

  buildOutcome1 = ->
    buildOutcome(
      "calculation_method" : "decaying_average"
      "calculation_int" : "65"
    )

  buildOutcome = (options) ->
    base =
      "context_type" : "Course"
      "context_id" : 1
      "outcome_group" :
        "outcomes_url" : "blah"
      "outcome" :
        "id" : 1
        "title" : "Outcome1"
        "description" : "outcome1 test"
        "context_type" : "Course"
        "context_id" : 1
        "points_possible" : "5"
        "mastery_points" : "3"
        "url" : "blah"
        "calculation_method" : "decaying_average"
        "calculation_int" : 65
        "assessed" : false
        "can_edit" : true
    $.extend base.outcome, options if options
    base

  createView = (opts) ->
    view = new OutcomeView(opts)
    view.$el.appendTo $('#fixtures')
    view.render()

  module 'OutcomeView',
    setup: ->
      @outcome1 = outcome1()

    teardown: ->
      #@outcomeView.remove()

  changeSelectedCalcMethod = (view, calcMethod) ->
    view.$el.find('#calculation_method').val(calcMethod)
    view.$el.find('#calculation_method').trigger('change')

  checkCalcOption = (show, view, calcMethod, calcInt) ->
    if show
      equal view.$el.find('#calculation_method').data('calculation-method'), calcMethod
      equal view.$el.find('#calculation_int').text(), calcInt if calcMethod not in ['highest', 'latest']
    else
      equal view.$el.find('#calculation_method').val(), calcMethod
      equal view.$el.find('#calculation_int').val(), calcInt if calcMethod not in ['highest', 'latest']

    if calcMethod in ['highest', 'latest']
      ok not view.$el.find('#calculation_int_left_side').is(':visible')
    else
      ok view.$el.find('#calculation_int_left_side').is(':visible')

  test 'outcome is created successfully', ->
    ok @outcome1.get('context_id'), "upper context id"
    ok @outcome1.outcomeLink
    ok @outcome1.outcomeLink.context_id
    ok @outcome1.outcomeLink.context_type
    ok @outcome1.outcomeLink.outcome
    ok @outcome1.outcomeLink.outcome.context_id
    ok @outcome1.outcomeLink.outcome.context_type
    ok @outcome1.outcomeLink.outcome.title
    ok @outcome1.outcomeLink.outcome.id

  test 'calculation method of decaying_average is rendered properly on show', ->
    view = createView(model: @outcome1, state: 'show')
    ok view.$el.find('#calculation_method').length
    equal view.$el.find('#calculation_method').data('calculation-method'), 'decaying_average'
    equal view.$el.find('#calculation_int').text(), '65'
    ok view.$el.find('#calculation_int_left_side').is(':visible')
    view.remove()

  test 'calculation method of n mastery is rendered properly on show', ->
    view = createView(model: newOutcome('calculation_method' : 'n_mastery', 'calculation_int' : 2), state: 'show')
    equal view.$el.find('#calculation_method').data('calculation-method'), 'n_mastery'
    equal view.$el.find('#calculation_int').text(), '2'
    ok view.$el.find('#calculation_int_left_side').is(':visible')
    view.remove()

  test 'calculation method of highest is rendered properly on show', ->
    view = createView(model: newOutcome('calculation_method' : 'highest'), state: 'show')
    equal view.$el.find('#calculation_method').data('calculation-method'), 'highest'
    ok not view.$el.find('#calculation_int_left_side').is(':visible')
    view.remove()

  test 'calculation method of latest is rendered properly on show', ->
    view = createView(model: newOutcome('calculation_method' : 'latest'), state: 'show')
    equal view.$el.find('#calculation_method').data('calculation-method'), 'latest'
    ok not view.$el.find('#calculation_int_left_side').is(':visible')
    view.remove()

  test 'calculation method of decaying_average is rendered properly on edit', ->
    view = createView(model: newOutcome('calculation_method' : 'decaying_average', 'calculation_int' : 65), state: 'edit')
    equal view.$el.find('#calculation_method').val(), 'decaying_average'
    equal view.$el.find('#calculation_int').val(), '65'
    ok view.$el.find('#calculation_int_left_side').is(':visible')
    view.remove()

  test 'calculation method of n mastery is rendered properly on edit', ->
    view = createView(model: newOutcome('calculation_method' : 'n_mastery', 'calculation_int' : 2), state: 'edit')
    equal view.$el.find('#calculation_method').val(), 'n_mastery'
    equal view.$el.find('#calculation_int').val(), '2'
    ok view.$el.find('#calculation_int_left_side').is(':visible')
    view.remove()

  test 'calculation method of highest is rendered properly on edit', ->
    view = createView(model: newOutcome('calculation_method' : 'highest'), state: 'edit')
    equal view.$el.find('#calculation_method').val(), 'highest'
    ok not view.$el.find('#calculation_int_left_side').is(':visible')
    view.remove()

  test 'calculation method of latest is rendered properly on edit', ->
    view = createView(model: newOutcome('calculation_method' : 'latest'), state: 'edit')
    equal view.$el.find('#calculation_method').val(), 'latest'
    ok not view.$el.find('#calculation_int_left_side').is(':visible')
    view.remove()

  test 'calculation method is rendered properly on add', ->
    view = createView(model: newOutcome(), state: 'add')
    # The default calculation method is decaying average with an int of 65
    equal view.$el.find('#calculation_method').val(), 'decaying_average'
    equal view.$el.find('#calculation_int').val(), '65'
    ok view.$el.find('#calculation_int_left_side').is(':visible')
    view.remove()

  test 'calculation int updates when the calculation method is changed', ->
    view = createView(model: newOutcome('calculation_method' : 'decaying_average', 'calculation_int' : 4), state: 'edit')
    equal view.$el.find('#calculation_method').val(), 'decaying_average'
    equal view.$el.find('#calculation_int').val(), '4'
    equal view.$el.find('#calculation_int_example').text(), "Last item is 75% of mastery.  Average of 'the rest' is 25% of mastery"
    changeSelectedCalcMethod(view, 'n_mastery')
    equal view.$el.find('#calculation_method').val(), 'n_mastery'
    equal view.$el.find('#calculation_int').val(), '4'
    equal view.$el.find('#calculation_int_example').text(), "Must achieve mastery at least 2 times.  Must also complete 2 items for calculation. Scores above mastery will be averaged to calculate final score."
    changeSelectedCalcMethod(view, 'highest')
    equal view.$el.find('#calculation_method').val(), 'highest'
    equal view.$el.find('#calculation_int_example').text(), "Use the highest score"
    changeSelectedCalcMethod(view, 'latest')
    equal view.$el.find('#calculation_method').val(), 'latest'
    equal view.$el.find('#calculation_int_example').text(), "Use the most recent score"
    view.remove()

  test 'edit and delete buttons are disabled for outcomes that have been assessed', ->
    view = createView(model: newOutcome('assessed' : true, 'native' : true, 'can_edit' : true), state: 'show')
    ok view.$el.find('.edit_button').length > 0
    ok view.$el.find('.delete_button').length > 0
    ok view.$el.find('.edit_button').attr('disabled')
    ok view.$el.find('.delete_button').attr('disabled')
    view.remove()

  test 'edit and delete buttons are enabled for outcomes that have not been assessed', ->
    view = createView(model: newOutcome('assessed' : false, 'native' : true, 'can_edit' : true), state: 'show')
    ok view.$el.find('.edit_button').length > 0
    ok view.$el.find('.delete_button').length > 0
    ok not view.$el.find('.edit_button').attr('disabled')
    ok not view.$el.find('.delete_button').attr('disabled')
    view.remove()

  test 'an informative banner is displayed when edit/delete buttons are disabled', ->
    view = createView(model: newOutcome('assessed' : true, 'native' : true), state: 'show')
    ok view.$el.find('#assessed_info_banner').length > 0
    view.remove()

  test 'the banner is not displayed when edit/delete buttons are enabled', ->
    view = createView(model: newOutcome('assessed' : false, 'native' : true), state: 'show')
    ok not view.$el.find('#assessed_info_banner').length > 0

  test 'calculation int gets set intelligently when the calc method is changed', ->
    view = createView(model: newOutcome('calculation_method' : 'highest'), state: 'edit')
    changeSelectedCalcMethod(view, 'n_mastery')
    equal view.$el.find('#calculation_int').val(), '5'
    changeSelectedCalcMethod(view, 'decaying_average')
    equal view.$el.find('#calculation_int').val(), '65'
    changeSelectedCalcMethod(view, 'n_mastery')
    equal view.$el.find('#calculation_int').val(), '5'
    view.$el.find('#calculation_int').val('4')
    equal view.$el.find('#calculation_int').val(), '4'
    changeSelectedCalcMethod(view, 'decaying_average')
    equal view.$el.find('#calculation_int').val(), '4'
    changeSelectedCalcMethod(view, 'highest')
    changeSelectedCalcMethod(view, 'decaying_average')
    equal view.$el.find('#calculation_int').val(), '4'
    view.remove()

  test 'calc int is not incorrectly changed to 65 when starting as n mastery and 5', ->
    view = createView(model: newOutcome('calculation_method' : 'n_mastery', 'calculation_int' : 5), state: 'edit')
    changeSelectedCalcMethod(view, 'n_mastery')
    equal view.$el.find('#calculation_int').val(), '5'
    view.remove()
