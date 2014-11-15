define ['quiz_formula_solution'], (QuizFormulaSolution)->
  module "QuizForumlaSolution",
    setup: ->
    teardown: ->

  test 'constructor: property setting', ->
    solution = new QuizFormulaSolution("= 0")
    equal(solution.result, "= 0")

  checkValue = (input, expected)->
    solution = new QuizFormulaSolution(input)
    equal(solution.rawValue(), expected)

  checkText = (input, expected)->
    solution = new QuizFormulaSolution(input)
    equal(solution.rawText(), expected)

  test 'can parse out raw values', ->
    checkValue("= 0", 0)
    checkValue("= 2.5", 2.5)
    checkValue("= 17", 17)
    checkValue("= -25.12", -25.12)
    checkValue("= 1000000000.45", 1000000000.45)

  test 'parsing out text of value', ->
    checkText("= 0", "0")
    checkText("= 2.5", "2.5")
    checkText("= 17", "17")
    checkText("= -25.12", "-25.12")
    checkText("= 1000000000.45", "1000000000.45")

  test "parses bad numbers effectively", ->
    solution = new QuizFormulaSolution("= NotReallyValuable")
    ok(isNaN(solution.rawValue()))
    solution = new QuizFormulaSolution(null)
    ok(isNaN(solution.rawValue()))
    solution = new QuizFormulaSolution(undefined)
    ok(isNaN(solution.rawValue()))

  module "QuizForumlaSolution#isValid",
    setup: ->
    teardown: ->

  checkSolutionValidity = (input, validity)->
    solution = new QuizFormulaSolution(input)
    equal(solution.isValid(), validity)

  test 'false without starting with =', ->
    checkSolutionValidity("0", false)

  test 'false if NaN', ->
    checkSolutionValidity("= NaN", false)

  test 'false if Infinity', ->
    checkSolutionValidity("= Infinity", false)

  test 'false if not a number', ->
    checkSolutionValidity("= ABCDE", false)

  test 'true for valid number', ->
    checkSolutionValidity("= 2.5", true)

  test 'true for 0', ->
    checkSolutionValidity("= 0", true)
