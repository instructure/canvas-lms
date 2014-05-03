define [
  'jquery'
], ($) ->
  $(document).on 'keydown', '[role=button], [role=checkbox]', (e) ->
      if e.keyCode == 13
          $(e.target).trigger('keyclick')
  $(document).on 'keyup', '[role=button], [role=checkbox]', (e) ->
      if e.keyCode == 32
          $(e.target).trigger('keyclick')
