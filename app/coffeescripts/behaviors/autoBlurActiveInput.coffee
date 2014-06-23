define ['jquery'], ($) ->
  blurActiveInput = false
  initialized     = false
  
  (enable=on) ->
    blurActiveInput = enable
    return if initialized
    initialized = true

    # ensure that blur/change/focus events fire for the active form element
    # whenever the window gains or loses focus
    #
    # this is particularly useful for taking quizzes, where we do some stuff
    # whenever you answer a question (validate it, mark it as answered in the
    # UI, save the submission, etc.). this way it works correctly when you
    # click into tiny (iframe, so a separate window), or click on the chrome
    # outside of the viewport (e.g. change tabs). see #7475
    $(window).bind
      blur: (e) ->
        if blurActiveInput and document.activeElement and window is e.target
          $(document.activeElement).filter(':input').change().triggerHandler('blur')
      focus: (e) ->
        if blurActiveInput and document.activeElement and window is e.target
          $(document.activeElement).filter(':input').triggerHandler('focus')
