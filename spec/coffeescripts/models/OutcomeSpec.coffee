define [
  'compiled/models/Outcome'
], (Outcome) ->

  module "Outcome",

    setup: ->
      @accountOutcome =
        "context_type" : "Account"
        "context_id" : 1
        "outcome" :
          "title" : "Account Outcome"
          "context_type" : "Course"
          "context_id" : 1
          "calculation_method" : "decaying_average"
          "calculation_int" : 65
      @nativeOutcome =
        "context_type" : "Course"
        "context_id" : 2
        "outcome" :
          "title" : "Native Course Outcome"
          "context_type" : "Course"
          "context_id" : 2

  test "default calculation method settings not set if calculation_method exists", ->
    spy = @spy(Outcome.prototype, 'setDefaultCalcSettings')
    outcome = new Outcome(@accountOutcome, { parse: true })
    ok not spy.called

  test "default calculation method settings set if calculation_method is null", ->
    spy = @spy(Outcome.prototype, 'setDefaultCalcSettings')
    outcome = new Outcome(@nativeOutcome, { parse: true })
    ok spy.calledOnce
