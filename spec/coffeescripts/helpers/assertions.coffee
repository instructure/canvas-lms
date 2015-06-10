define ['jquery'], ($) ->

  isVisible: ($el, message = '') ->
    ok $el.length, "elements found"
    ok $el.is(':visible'), "#{$el} is visible " + message

  isHidden: ($el, message) ->
    ok $el.length, "elements found"
    ok !$el.is(':visible'), "#{$el} is hidden " + message

  hasClass: ($el, className, message) ->
    ok $el.length, "elements found"
    ok $el.hasClass(className), "#{$el} has class #{className} " + message

