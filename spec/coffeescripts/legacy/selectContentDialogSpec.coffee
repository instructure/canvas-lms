define [
  'select_content_dialog'
], (SelectContentDialog) ->
  QUnit.module "SelectContentDialog: Dialog options",
    setup: ->
      @spy($.fn, 'dialog')
      $("#fixtures").html("<div id='select_context_content_dialog'></div>")

    teardown: ->
      $(".ui-dialog").remove()
      $("#fixtures").html("")

  test "opens a dialog with the width option", ->
    width = 500

    INST.selectContentDialog({width: width})
    equal $.fn.dialog.getCall(0).args[0].width, width

  test "opens a dialog with the height option", ->
    height = 100

    INST.selectContentDialog({height: height})
    equal $.fn.dialog.getCall(0).args[0].height, height

  test "opens a dialog with the dialog_title option", ->
    dialogTitle = "To be, or not to be?"

    INST.selectContentDialog({dialog_title: dialogTitle})
    equal $.fn.dialog.getCall(0).args[0].title, dialogTitle
