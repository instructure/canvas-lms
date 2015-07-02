define [
  'jquery'
  'Backbone'
  'compiled/models/Outcome'
  'compiled/views/outcomes/OutcomeView'
], ($, Backbone, Outcome, OutcomeView) ->

  newOutcome = (outcomeOptions, outcomeLinkOptions) ->
    new Outcome(buildOutcome(outcomeOptions, outcomeLinkOptions), { parse: true })

  outcome1 = ->
    new Outcome(buildOutcome1(), { parse: true })

  buildOutcome1 = ->
    buildOutcome(
      "calculation_method" : "decaying_average"
      "calculation_int" : "65"
    )

  buildOutcome = (outcomeOptions, outcomeLinkOptions) ->
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
    $.extend base.outcome, outcomeOptions if outcomeOptions
    $.extend base, outcomeLinkOptions if outcomeLinkOptions
    base

  createView = (opts) ->
    view = new OutcomeView(opts)
    view.$el.appendTo($("#fixtures"))
    view.render()

  module 'OutcomeView',
    setup: ->
      @outcome1 = outcome1()

    teardown: ->
      document.getElementById("fixtures").innerHTML = ""

  changeSelectedCalcMethod = (view, calcMethod) ->
    view.$('#calculation_method').val(calcMethod)
    view.$('#calculation_method').trigger('change')

  checkCalcOption = (show, view, calcMethod, calcInt) ->
    if show
      equal view.$('#calculation_method').data('calculation-method'), calcMethod
      equal view.$('#calculation_int').text(), calcInt if calcMethod not in ['highest', 'latest']
    else
      equal view.$('#calculation_method').val(), calcMethod
      equal view.$('#calculation_int').val(), calcInt if calcMethod not in ['highest', 'latest']

    if calcMethod in ['highest', 'latest']
      ok not view.$('#calculation_int_left_side').is(':visible')
    else
      ok view.$('#calculation_int_left_side').is(':visible')

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
    ok view.$('#calculation_method').length
    equal view.$('#calculation_method').data('calculation-method'), 'decaying_average'
    equal view.$('#calculation_int').text(), '65'
    ok view.$('#calculation_int_left_side').is(':visible')
    view.remove()

  test 'calculation method of n mastery is rendered properly on show', ->
    view = createView(model: newOutcome('calculation_method' : 'n_mastery', 'calculation_int' : 2), state: 'show')
    equal view.$('#calculation_method').data('calculation-method'), 'n_mastery'
    equal view.$('#calculation_int').text(), '2'
    ok view.$('#calculation_int_left_side').is(':visible'),
      'calculation_int_left_side should be visible'
    view.remove()

  test 'calculation method of highest is rendered properly on show', ->
    view = createView(model: newOutcome({
      'calculation_method' : 'highest'
      'calculation_int': null
    }), state: 'show')
    equal view.$('#calculation_method').data('calculation-method'), 'highest'
    ok not view.$('#calculation_int_left_side').is(':visible')
    view.remove()

  test 'calculation method of latest is rendered properly on show', ->
    view = createView(model: newOutcome({
      'calculation_method' : 'latest'
      'calculation_int': null
    }), state: 'show')
    equal view.$('#calculation_method').data('calculation-method'), 'latest'
    ok not view.$('#calculation_int_left_side').is(':visible')
    view.remove()

  test 'calculation method of decaying_average is rendered properly on edit', ->
    view = createView(model: newOutcome('calculation_method' : 'decaying_average', 'calculation_int' : 65), state: 'edit')
    equal view.$('#calculation_method').val(), 'decaying_average'
    equal view.$('#calculation_int').val(), '65'
    ok view.$('#calculation_int_left_side').is(':visible')
    view.remove()

  test 'calculation method of n mastery is rendered properly on edit', ->
    view = createView(model: newOutcome('calculation_method' : 'n_mastery', 'calculation_int' : 2), state: 'edit')
    equal view.$('#calculation_method').val(), 'n_mastery'
    equal view.$('#calculation_int').val(), '2'
    ok view.$('#calculation_int_left_side').is(':visible')
    view.remove()

  test 'calculation method of highest is rendered properly on edit', ->
    view = createView(model: newOutcome({
      'calculation_method' : 'highest'
      'calculation_int': null
    }), state: 'edit')
    equal view.$('#calculation_method').val(), 'highest'
    ok not view.$('#calculation_int_left_side').is(':visible')
    view.remove()

  test 'calculation method of latest is rendered properly on edit', ->
    view = createView(model: newOutcome({
      'calculation_method' : 'latest'
      'calculation_int': null
    }), state: 'edit')
    equal view.$('#calculation_method').val(), 'latest'
    ok not view.$('#calculation_int_left_side').is(':visible')
    view.remove()

  test 'calculation method is rendered properly on add', ->
    view = createView(model: newOutcome(), state: 'add')
    # The default calculation method is decaying average with an int of 65
    equal view.$('#calculation_method').val(), 'decaying_average'
    equal view.$('#calculation_int').val(), '65'
    ok view.$('#calculation_int_left_side').is(':visible')
    view.remove()

  test 'calculation int updates when the calculation method is changed', ->
    view = createView(model: newOutcome('calculation_method' : 'decaying_average', 'calculation_int' : 75), state: 'edit')
    equal view.$('#calculation_method').val(), 'decaying_average'
    equal view.$('#calculation_int').val(), '75'
    ok view.$('#calculation_int_example').text().match /75\% of mastery weight/
    changeSelectedCalcMethod(view, 'n_mastery')
    equal view.$('#calculation_method').val(), 'n_mastery'
    equal view.$('#calculation_int').val(), '5'
    ok view.$('#calculation_int_example').text().match /achieve mastery at least 5 times/
    changeSelectedCalcMethod(view, 'highest')
    equal view.$('#calculation_method').val(), 'highest'
    ok view.$('#calculation_int_example').text().match /highest score/
    changeSelectedCalcMethod(view, 'latest')
    equal view.$('#calculation_method').val(), 'latest'
    ok view.$('#calculation_int_example').text().match /most recent/
    view.remove()

  test 'edit and delete buttons are disabled for outcomes that have been assessed', ->
    view = createView
      model: newOutcome(
        { 'assessed' : true, 'native' : true, 'can_edit' : true },
        { 'assessed' : true }),
      state: 'show'
    ok view.$('.edit_button').length > 0
    ok view.$('.delete_button').length > 0
    ok view.$('.edit_button').attr('disabled')
    ok view.$('.delete_button').attr('disabled')
    view.remove()

  test 'edit and delete buttons are enabled for outcomes that have not been assessed', ->
    view = createView
      model: newOutcome(
        { 'assessed' : false, 'native' : true, 'can_edit' : true },
        { 'assessed' : false }),
      state: 'show'
    ok view.$('.edit_button').length > 0
    ok view.$('.delete_button').length > 0
    ok not view.$('.edit_button').attr('disabled')
    ok not view.$('.delete_button').attr('disabled')
    view.remove()

  test 'an informative banner is displayed when edit/delete buttons are disabled', ->
    view = createView
      model: newOutcome(
        { 'assessed' : true, 'native' : true },
        { 'assessed' : true }),
      state: 'show'
    ok view.$('#assessed_info_banner').length > 0
    view.remove()

  test 'the banner is not displayed when edit/delete buttons are enabled', ->
    view = createView(model: newOutcome('assessed' : false, 'native' : true), state: 'show')
    ok not view.$('#assessed_info_banner').length > 0

  test 'calculation int gets set intelligently when the calc method is changed', ->
    view = createView(model: newOutcome('calculation_method' : 'highest'), state: 'edit')
    changeSelectedCalcMethod(view, 'n_mastery')
    equal view.$('#calculation_int').val(), '5'
    changeSelectedCalcMethod(view, 'decaying_average')
    equal view.$('#calculation_int').val(), '65'
    changeSelectedCalcMethod(view, 'n_mastery')
    equal view.$('#calculation_int').val(), '5'
    view.$('#calculation_int').val('4')
    equal view.$('#calculation_int').val(), '4'
    changeSelectedCalcMethod(view, 'decaying_average')
    equal view.$('#calculation_int').val(), '65'
    changeSelectedCalcMethod(view, 'highest')
    changeSelectedCalcMethod(view, 'decaying_average')
    equal view.$('#calculation_int').val(), '65'
    view.remove()

  test 'calc int is not incorrectly changed to 65 when starting as n mastery and 5', ->
    view = createView(model: newOutcome('calculation_method' : 'n_mastery', 'calculation_int' : 5), state: 'edit')
    changeSelectedCalcMethod(view, 'n_mastery')
    equal view.$('#calculation_int').val(), '5'
    view.remove()

  test 'delete button is disabled for account outcomes that have been assessed in this course', ->
    view = createView
      model: newOutcome(
        {
          'assessed' : true,
          'native' : false,
          'can_edit' : true,
          'context_type' : 'Account'
        },
        {
          'assessed' : true
        }
      ),
      state: 'show'

    ok view.$el.find('.delete_button').length > 0
    ok view.$el.find('.delete_button').attr('disabled')
    view.remove()

  test 'delete button is enabled for account outcomes that have been assessed, but not in this course', ->
    view = createView
      model: newOutcome(
        {
          'assessed' : true,
          'native' : false,
          'can_edit' : true,
          'context_type' : 'Account'
        },
        {
          'assessed' : false
        }
      ),
      state: 'show'

    ok view.$el.find('.delete_button').length > 0
    ok not view.$el.find('.delete_button').attr('disabled')
    view.remove()

  test 'validates display_name length', ->
    long_name = "long outcome name "
    long_name += long_name for _ in [1..5]
    ok long_name.length > 256
    view = createView(model: @outcome1, state: 'edit')
    view.$('#display_name').val(long_name)
    view.$('#display_name').trigger('change')
    ok !view.isValid()
    ok view.errors.display_name
    view.remove()
