//
// Copyright (C) 2014 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import _ from 'underscore'
import Backbone from 'Backbone'
import $ from 'jquery'
import Markup from 'jst/quizzes/LDBLoginPopup'
import htmlEscape from 'str/htmlEscape'
import 'jquery.toJSON'

// Consumes an event and stops it from propagating.
function consume(e) {
  if (!e) return
  if (e.preventDefault) e.preventDefault()
  if (e.stopPropagation) e.stopPropagation()
  return false
}

export default class LDBLoginPopup extends Backbone.View {
  static initClass() {
    // @config {String} url
    //
    // (POST) Endpoint for creating and destroying sessions (login).
    this.prototype.url = '/login/canvas'

    // @config {Function} template
    //
    // Handlebars template to use as the popup's markup.
    this.prototype.template = Markup

    // @config {Object} options
    this.prototype.options = {
      // @config {Boolean} [options.sticky=true]
      //
      // Turn on sticky mode so that the pop-up will re-pop if the student closes
      // it without being logged in.
      sticky: true,

      // @config {Object} options.window
      //
      // Window options to pass to window.open(). See this link for the full
      // reference: https://developer.mozilla.org/en-US/docs/Web/API/Window.open
      window: {
        location: false,
        menubar: false,
        status: false,
        toolbar: false,
        fullscreen: false,
        width: 480,
        height: 480
      }
    }
  }
  initialize(options) {
    // @property {window} whnd The popup window handle.
    // @private
    let whnd = undefined

    // @property {CSSStyleSheet[]} styleSheets
    // @private
    //
    // The set of stylesheets to inject into the dialog, parsed from the current
    // page's available stylesheets.
    let styleSheets = undefined

    // @property {jQuery} $delegate
    // @private
    //
    // Used for accepting and emitting events.
    const $delegate = $(this)

    // @property {jQuery} $inputSink
    // @private
    //
    // An element that covers the entire screen and consumes all input.
    //
    // We'll attach this to the DOM when we want to intercept background input
    // instead of binding to 'click', 'mousedown', or 'keydown' handlers on all
    // of window, document, and document.body to ensure that everything gets
    // captured.
    let $inputSink = undefined

    _.extend(this.options, options)

    const windowOptions = _.map(this.options.window, (v, k) =>
      [k, _.isBoolean(v) ? (v ? 'yes' : 'no') : v].join('=')
    ).join(',')

    // @method on
    // @public
    //
    // Install an event handler.
    this.on = _.bind($delegate.on, $delegate)
    this.one = _.bind($delegate.one, $delegate)

    // @method off
    // @public
    //
    // Remove a previously registered event handler.
    this.off = _.bind($delegate.off, $delegate)

    // When the popup is closed manually by clicking the X in the titlebar
    // in LDB, it will not honor nor trigger the `onbeforeunload` event, so
    // we won't be able to clean up properly.
    //
    // @return {Boolean}
    //   Whether the popup is stuck and needs to be cleaned up.
    function isStuck() {
      if (whnd) {
        try {
          whnd.document
        } catch (e) {
          if (/Permission/.test(e.message)) return true
        }
      }
      return false
    }

    // Unlocks the background and discards the window handle, but if the student
    // is still not logged in, it will automatically re-launch the popup.
    //
    // @emits close
    function reset() {
      unlockBackground()
      whnd = null
      $delegate.triggerHandler('close')
      return null
    }

    // Brings the pop-up into the foreground and focuses it. In case the popup
    // is stuck, it will clean up and let the event propagate.
    function bringToFront(e) {
      if (isStuck()) {
        reset()
        return true // let it propagate
      }

      try {
        whnd.document.focus()
      } catch (error) {
        $(whnd.document).focus()
      }

      return consume(e)
    }

    // Prevent any user input from going through to the parent page (the quiz
    // one) and instead make it so that any input brings the pop-up to the
    // foreground, forcing the student to re-login (or close the pop-up.)
    //
    // See #exec()
    const lockBackground = () => $inputSink.appendTo(document.body)

    // Lift the restriction on user input in the background.
    //
    // See #reset()
    var unlockBackground = () => $inputSink.detach()

    const login = e => {
      const consumptionRc = consume(e)

      const credentials = $(e.target)
        .closest('form')
        .toJSON()

      const authenticate = this.authenticate(credentials)

      authenticate.then(function(rc) {
        $delegate.triggerHandler('login_success')
        whnd.close()
        reset()
        return rc
      })

      authenticate.fail(function(xhrError) {
        $delegate.triggerHandler('login_failure', xhrError)
        return xhrError
      })

      return consumptionRc
    }

    // Called when the DOM in the popup window is ready.
    //
    // @emits open
    function render() {
      const $document = $(whnd.document)
      const $head = $(whnd.document.head)

      // Inject the stylesheets.
      _(styleSheets).each(function(href) {
        $head.append(`<link rel="stylesheet" href="${htmlEscape(href)}" />`)
      })

      // Show the form.
      $document.find('.hide').removeClass('hide')
      $document.find('.btn-primary').on('click', login)
      $delegate.triggerHandler('open', whnd.document)
    }

    // @public
    //
    // Main routine; display the login pop-up and lock down the background.
    // No-op if the pop-up is already shown.
    //
    // @emits open
    //
    // @return {window}
    // The pop-up window handle.
    this.exec = () => {
      if (isStuck()) reset()

      if (whnd) {
        bringToFront()
        return whnd
      }

      lockBackground()

      whnd = window.open('about:blank', '_blank', windowOptions, false)
      whnd.document.write(this.template({}))
      whnd.onbeforeunload = reset
      whnd.onload = render
      whnd.document.close()
      return whnd
    }

    // Store the links to the stylesheets
    styleSheets = _(document.styleSheets)
      .chain()
      .map(styleSheet => styleSheet.href)
      .compact()
      .value()

    $inputSink = $('<div />')
      .on('click', bringToFront)
      .css({
        'z-index': 1000,
        position: 'fixed',
        left: 0,
        right: 0,
        top: 0,
        bottom: 0
      })

    if (this.options.sticky) {
      let relaunch = undefined

      this.on('login_failure.sticky', () => (relaunch = true))

      this.on('login_success.sticky', () => (relaunch = false))

      return this.on('close.sticky', function() {
        if (relaunch) {
          setTimeout(this.exec, 1)
        }
      })
    }
  }

  // Authenticate a student with the provided credentials. Override this if
  // you need a custom authenticator.
  //
  // @param {String} credentials
  // Credentials in application/x-www-form-urlencoded payload style.
  //
  // @return {$.Deferred} Authentication promise.
  authenticate(credentials) {
    return $.ajax({
      type: 'POST',
      url: this.url,
      data: JSON.stringify(credentials),
      global: false,
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json'
      }
    })
  }
}
LDBLoginPopup.initClass()
