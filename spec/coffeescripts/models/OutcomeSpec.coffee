define [
  'compiled/models/Outcome'
], (Outcome) ->

  module "Outcome",

    setup: ->
      @accountOutcome =
        "context_type" : "Account"
        "context_id" : 1
        "outcome_group" :
          "outcomes_url" : "blah"
        "outcome" :
          "title" : "Account Outcome"
          "description" : "an account outcome"
          "context_type" : "Course"
          "context_id" : 1
          "points_possible" : "5"
          "mastery_points" : "3"
          "url" : "blah"
          "calculation_method" : "decaying_average"
          "calculation_int" : 65
          "assessed" : false
          "can_edit" : true
      @nativeOutcome =
        "context_type" : "Course"
        "context_id" : 2
        "outcome_group" :
          "outcomes_url" : "blah2"
        "outcome" :
          "title" : "Native Course Outcome"
          "description" : "a native course outcome"
          "context_type" : "Course"
          "context_id" : 2
          "points_possible" : "5"
          "mastery_points" : "3"
          "url" : "blah2"
          "calculation_method" : "decaying_average"
          "calculation_int" : 65
          "assessed" : false
          "can_edit" : true

  test "native returns true for a course outcome", ->
    outcome = new Outcome(@accountOutcome, { parse: true })
    equal outcome.isNative(), false

  test "native returns false for a course outcome imported from the account level", ->
    outcome = new Outcome(@nativeOutcome, { parse: true })
    equal outcome.isNative(), true

