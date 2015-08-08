define [
  'jquery'
  'underscore',
  'compiled/util/rgb2hex'
], ($, _, rgb2hex) ->
  ContextColorer = {
    persistContextColors: (colorsByContext, userId) ->
      _.each(colorsByContext, (color, contextCode) ->
        if contextCode.match(/course/)
          if color.match(/rgb/)
            hexcodeColor = rgb2hex(color)
          else
            hexcodeColor = color

          $.ajax({
            url: '/api/v1/users/' + userId + '/colors/' + contextCode,
            type: 'PUT',
            data: { hexcode: hexcodeColor}
          })
      )
  }
