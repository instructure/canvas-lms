require [
  'jquery'
], ($) ->
  # Makes toggle components behave like buttons for a11y
  # (they should respond to the ENTER key)
  KEY_CODE_ENTER = 13
  $(document).on 'keydown', '.ic-Super-toggle__input', (event) ->
    if event.which == KEY_CODE_ENTER
      $(event.target).click()
