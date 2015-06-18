define [
  'jquery'
  'underscore'
  'compiled/fn/preventDefault'
  'jqueryui/dialog'
], ($, _, preventDefault) ->

  $.fn.fixDialogButtons = ->
    this.each ->
      $dialog = $(this)
      $buttons = $dialog.find(".button-container:last .btn, button[type=submit]")
      if $buttons.length
        # position hack for safari to still see the submit buttons
        $dialog.find(".button-container:last, button[type=submit]").css({position:"absolute",left:"-9999px"})
        buttons = $.map $buttons.toArray(), (button) ->
          $button = $(button)
          classes = $button.attr('class') ? ''
          id = $button.attr('id')

          # if you add the class 'dialog_closer' to any of the buttons,
          # clicking it will cause the dialog to close
          if $button.is('.dialog_closer')
            $button.off '.fixdialogbuttons'
            $button.on 'click.fixdialogbuttons', preventDefault -> $dialog.dialog('close')

          if $button.prop('type') is 'submit' && $button[0].form
            classes += ' button_type_submit'

          return {
            text: $button.text()
            "data-text-while-loading": $button.data("textWhileLoading")
            click: -> $button.click()
            class: classes
            id: id
          }
        # put the primary button(s) on the far right
        buttons = _.sortBy buttons, (button) ->
          if button.class.match(/btn-primary/) then 1 else 0
        $dialog.dialog "option", "buttons", buttons
