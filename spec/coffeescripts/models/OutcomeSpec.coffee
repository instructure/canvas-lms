define [
  'compiled/models/Outcome'
], (Outcome) ->

  QUnit.module "Outcome",

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

  test "native returns true for a course outcome", ->
    outcome = new Outcome(@accountOutcome, { parse: true })
    equal outcome.isNative(), false

  test "native returns false for a course outcome imported from the account level", ->
    outcome = new Outcome(@nativeOutcome, { parse: true })
    equal outcome.isNative(), true

  test "default calculation method settings not set if calculation_method exists", ->
    spy = @spy(Outcome.prototype, 'setDefaultCalcSettings')
    outcome = new Outcome(@accountOutcome, { parse: true })
    ok not spy.called

  test "default calculation method settings set if calculation_method is null", ->
    spy = @spy(Outcome.prototype, 'setDefaultCalcSettings')
    outcome = new Outcome(@nativeOutcome, { parse: true })
    ok spy.calledOnce
