define [], ()->

  # DONT create global functions if you can avoid it, this is just here
  # to show how you can monkey patch them safely in tests
  window.stupidlyAwesomeGlobalFunction = (message)=>
    console.log(message)

  # this isn't real production code, it's just a module to hook up
  # specs against to demonstrate some best practices for JS spec writing
  class Reference
    sum: (a, b)->
      return a + b

    sendMessage: (message)->
      window.stupidlyAwesomeGlobalFunction(message)

