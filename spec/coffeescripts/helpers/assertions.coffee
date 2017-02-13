define ['jquery', 'underscore', 'axe-core'], ($, _, axe) ->

  isVisible: ($el, message = '') ->
    ok $el.length, "elements found"
    ok $el.is(':visible'), "#{$el} is visible " + message

  isHidden: ($el, message) ->
    ok $el.length, "elements found"
    ok !$el.is(':visible'), "#{$el} is hidden " + message

  hasClass: ($el, className, message) ->
    ok $el.length, "elements found"
    ok $el.hasClass(className), "#{$el} has class #{className} " + message

  isAccessible: ($el, done, options) ->
    options = options || {}

    el = $el[0]

    axeConfig = runOnly:
      type: "tag"
      values: [ "wcag2a", "wcag2aa", "section508", "best-practice" ]

    axe.a11yCheck el, axeConfig, (result) ->
      ignores = options.ignores || []
      violations = _.reject(result.violations, (violation) ->
        ignores.indexOf(violation.id) >= 0
      )

      err = violations.map((violation) ->
        [ "[" + violation.id + "] " + violation.help, violation.helpUrl + "\n" ].join "\n"
      )

      ok(violations.length is 0, err)

      done()

  contains: (string, substring) ->
    QUnit.assert.push string.indexOf(substring) > -1, string, substring, "expected string not found in actual"
