define ['jquery'], ($) ->

  $.fn.toString = ->
    id = this.attr 'id'
    className = this.attr('class').replace(/\s/g, '.')
    tag = this[0].tagName.toLowerCase()
    str = tag
    str += "##{id}" if id
    str += ".#{className}" if className
    "<#{str}>"

  isVisible: ($el, message) ->
    ok $el.is(':visible'), "#{$el} is visible " + message

  isHidden: ($el, message) ->
    ok !$el.is(':visible'), "#{$el} is hidden " + message

  hasClass: ($el, className, message) ->
    ok $el.hasClass(className), "#{$el} has class #{className} " + message

