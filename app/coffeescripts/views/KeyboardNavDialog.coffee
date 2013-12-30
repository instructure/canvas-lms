define [
  'i18n!instructure'
  'Backbone'
  'jquery'
  'jqueryui/dialog'
], (I18n, {View}, $) ->

  class KeyboardNavDialog extends View

    el: '#keyboard_navigation'

    initialize: ->
      super
      @bindOpenKeys
      @

    # you're responsible for rendering the content via HB
    # and passing it in
    render: (content) ->
      @$el.html(content)
      @

    bindOpenKeys: ->
      activeElement = null
      $(document).keypress((e) =>
        commaOrQuestionMark = e.which == 44 || e.which == 63
        if (commaOrQuestionMark && !$(e.target).is(":input"))
          if(@$el.is(":visible"))
            @$el.dialog("close")
            if(activeElement)
              $(activeElement).focus()
          else
            activeElement = document.activeElement

            @$el.dialog(
              title: I18n.t 'titles.keyboard_shortcuts', "Keyboard Shortcuts"

              width: 400

              height: "auto"

              open: ->
                $(".navigation_list:first", @).focus()

              close: ->
                $("li", @).attr("tabindex", "") # prevents chrome bsod
                if(activeElement)
                  $(activeElement).focus()
            )
        )

