define ['jquery', 'underscore'], ($, _) ->

  closeDialog: ->
    $('.ui-dialog-content').dialog 'close'

  useOldDebounce: ->
    # this version of debounce works with sinon's useFakeTimers
    _.debounce = (func, wait, immediate) ->
      return ->
        context = this
        args = arguments
        timestamp = new Date()
        later = ->
          last = (new Date()) - timestamp
          if (last < wait)
            timeout = setTimeout(later, wait - last)
           else
            timeout = null
            result = func.apply(context, args) unless immediate
        callNow = immediate && !timeout
        timeout = setTimeout(later, wait) unless timeout
        result = func.apply(context, args) if callNow
        return result

  debounce: _.debounce

  useNormalDebounce: ->
    _.debounce = @debounce
