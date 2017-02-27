define ['compiled/Reference'], (Reference) ->

  # THE REFERENCE SPEC
  # This is a collection of best practice recommendations from specs
  # that have bitten us in the past either because they were too fragile,
  # too brittle, or annoying in some other way.  Please continue to add to
  # it whenever you go fix a bad practice in a JS spec so others can use 
  # it as a template when trying to write new JS specs

  # if you need to share state between functions like this
  # initialize the actual value during setup rather than at definition time,
  # just put the reference up here and null it out
  fixtures = null
  storedStupidAwesomeFunction = null

  QUnit.module "Reference",
    setup: ->
      # DO put any necessary DOM artifacts into #fixtures, not "body"
      fixtures = document.getElementById('fixtures')
      fixtures.innerHTML = "<div id='reference-dom'></div>"

      # DO save the original implementation of functions
      # that you inted to overwrite either in the setup or in individual
      # specs.  You can use it to repair state in teardown
      storedStupidAwesomeFunction = window.stupidlyAwesomeGlobalFunction
    teardown: ->
      # DO clean up the fixtures element if you use it,
      # don't just remove the view you know
      # about, blank the thing entirely, DOM state shouldn't bleed between
      # specs
      fixtures.innerHTML = ""

      # DO repair global state in a teardown, even if
      # you're only monkeying with it once, because errors that halt execution
      # in a given spec will stop the rest of that function from running
      window.stupidlyAwesomeGlobalFunction = storedStupidAwesomeFunction

  # DONT nest your tests within module, qunit won't complain, but it WILL
  # run the tests within the wrong module context (that is, whichever module
  # ran before this one
  test "a simple function", ()->
    ref = new Reference()
    equal(ref.sum(6, 4), 10)

  # DONT monkey patch some global function without fixing it afterwards, but
  # remember to fix it in a teardown (see docs in teardown above)
  test "stubbing out a global", ()->
    sentMessage = ""
    window.stupidlyAwesomeGlobalFunction = (message)->
      sentMessage = message
    ref = new Reference()
    ref.sendMessage("Hello, QUnit")
    equal(sentMessage, "Hello, QUnit")
