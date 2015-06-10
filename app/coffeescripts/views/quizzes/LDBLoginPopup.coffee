define [
  "underscore"
  "Backbone"
  "jquery"
  "jst/quizzes/LDBLoginPopup"
  "str/htmlEscape"
  "jquery.toJSON"
], (_, Backbone, $, Markup, htmlEscape) ->

  # Consumes an event and stops it from propagating.
  consume = (e) ->
    return  unless e
    e.preventDefault()  if e.preventDefault
    e.stopPropagation()  if e.stopPropagation
    false

  # An authentication pop-up that is usable inside the LDB in high-security
  # mode. The pop-up is capable of re-authenticating students during a quiz
  # taking session.
  #
  # The pop-up triggers events at interesting stages that you can hook into
  # using #on and #off (similar to the jQuery event interface). Here's a
  # breakdown of the events:
  #
  # @event open
  #   The pop-up has been created and brought to the foreground.
  #
  #   @param {window.document} document
  #     The pop-up window document, if you need to access its DOM.
  #
  # @event close
  #   The pop-up has been closed after the student has successfully
  #   re-authenticated themselves.
  #
  # @event login_success
  #   The student has successfully re-authenticated their session.
  #
  # @event login_failure
  #   Attempt to authenticate the student has failed, probably due to bad
  #   credentials.
  #
  #   @param {Object} xhrError
  #   XHR error as reported by #authenticate ($.ajax()).
  #
  # @example
  #   ldbLoginPopup = new LDBLoginPopup();
  #   ldbLoginPopup.on('login_success', function() {
  #     alert('Logged in!');
  #   });
  #   ldbLoginPopup.exec();
  class LDBLoginPopup extends Backbone.View
    initialize: (options) ->
      # @property {window} whnd The popup window handle.
      # @private
      whnd = undefined

      # @property {CSSStyleSheet[]} styleSheets
      # @private
      #
      # The set of stylesheets to inject into the dialog, parsed from the current
      # page's available stylesheets.
      styleSheets = undefined

      # @property {jQuery} $delegate
      # @private
      #
      # Used for accepting and emitting events.
      $delegate = $(this)

      # @property {jQuery} $inputSink
      # @private
      #
      # An element that covers the entire screen and consumes all input.
      #
      # We'll attach this to the DOM when we want to intercept background input
      # instead of binding to 'click', 'mousedown', or 'keydown' handlers on all
      # of window, document, and document.body to ensure that everything gets
      # captured.
      $inputSink = undefined

      _.extend @options, options

      windowOptions = _.map(@options.window, (v, k) ->
        [
          k
          (if _.isBoolean(v) then ((if v then "yes" else "no")) else v)
        ].join "="
      ).join(",")

      # @method on
      # @public
      #
      # Install an event handler.
      @on = _.bind($delegate.on, $delegate)
      @one = _.bind($delegate.one, $delegate)

      # @method off
      # @public
      #
      # Remove a previously registered event handler.
      @off = _.bind($delegate.off, $delegate)

      # When the popup is closed manually by clicking the X in the titlebar
      # in LDB, it will not honor nor trigger the `onbeforeunload` event, so
      # we won't be able to clean up properly.
      #
      # @return {Boolean}
      #   Whether the popup is stuck and needs to be cleaned up.
      isStuck = ->
        if whnd
          try
            whnd.document
          catch e
            return true  if /Permission/.test(e.message)
        false

      # Unlocks the background and discards the window handle, but if the student
      # is still not logged in, it will automatically re-launch the popup.
      #
      # @emits close
      reset = ->
        unlockBackground()
        whnd = null
        $delegate.triggerHandler "close"
        null

      # Brings the pop-up into the foreground and focuses it. In case the popup
      # is stuck, it will clean up and let the event propagate.
      bringToFront = (e) ->
        if isStuck()
          reset()
          return true # let it propagate

        try
          whnd.document.focus()
        catch error
          $(whnd.document).focus()

        consume e

      # Prevent any user input from going through to the parent page (the quiz
      # one) and instead make it so that any input brings the pop-up to the
      # foreground, forcing the student to re-login (or close the pop-up.)
      #
      # See #exec()
      lockBackground = ->
        $inputSink.appendTo document.body

      # Lift the restriction on user input in the background.
      #
      # See #reset()
      unlockBackground = ->
        $inputSink.detach()

      login = (e) =>
        consumptionRc = consume(e)

        credentials = $(e.target).closest("form").toJSON()

        authenticate = @authenticate(credentials)

        authenticate.then (rc) ->
          $delegate.triggerHandler "login_success"
          whnd.close()
          reset()
          return rc

        authenticate.fail (xhrError) ->
          $delegate.triggerHandler "login_failure", xhrError
          return xhrError

        consumptionRc

      # Called when the DOM in the popup window is ready.
      #
      # @emits open
      render = ->
        $document = $(whnd.document)
        $head = $(whnd.document.head)

        # Inject the stylesheets.
        _(styleSheets).each (href) ->
          $head.append "<link rel=\"stylesheet\" href=\"" + htmlEscape(href) + "\" />"
          return

        # Show the form.
        $document.find(".hide").removeClass "hide"
        $document.find(".btn-primary").on "click", login
        $delegate.triggerHandler "open", whnd.document
        return

      # @public
      #
      # Main routine; display the login pop-up and lock down the background.
      # No-op if the pop-up is already shown.
      #
      # @emits open
      #
      # @return {window}
      # The pop-up window handle.
      @exec = =>
        reset() if isStuck()

        if whnd
          bringToFront()
          return whnd

        lockBackground()

        whnd = window.open("about:blank", "_blank", windowOptions, false)
        whnd.document.write @template({})
        whnd.onbeforeunload = reset
        whnd.onload = render
        whnd.document.close()
        whnd

      # Store the links to the stylesheets
      styleSheets = _(document.styleSheets).chain().map((styleSheet) ->
        styleSheet.href
      ).compact().value()

      $inputSink = $("<div />").on("click", bringToFront).css {
        "z-index": 1000
        position: "fixed"
        left: 0
        right: 0
        top: 0
        bottom: 0
      }

      if @options.sticky
        relaunch = undefined

        @on "login_failure.sticky", ->
          relaunch = true

        @on "login_success.sticky", ->
          relaunch = false

        @on "close.sticky", ->
          if relaunch
            setTimeout @exec, 1

    # @config {String} url
    #
    # (POST) Endpoint for creating and destroying sessions (login).
    url: "/login?nonldap=true"

    # @config {Function} template
    #
    # Handlebars template to use as the popup's markup.
    template: Markup

    # @config {Object} options
    options:
      # @config {Boolean} [options.sticky=true]
      #
      # Turn on sticky mode so that the pop-up will re-pop if the student closes
      # it without being logged in.
      sticky: true

      # @config {Object} options.window
      #
      # Window options to pass to window.open(). See this link for the full
      # reference: https://developer.mozilla.org/en-US/docs/Web/API/Window.open
      window:
        location: false
        menubar: false
        status: false
        toolbar: false
        fullscreen: false
        width: 480
        height: 480

    # Authenticate a student with the provided credentials. Override this if
    # you need a custom authenticator.
    #
    # @param {String} credentials
    # Credentials in application/x-www-form-urlencoded payload style.
    #
    # @return {$.Deferred} Authentication promise.
    authenticate: (credentials) ->
      $.ajax
        type: "POST"
        url: @url
        data: JSON.stringify(credentials)
        global: false
        headers:
          'Content-Type': 'application/json'
          'Accept': 'application/json'
