define [
  'jquery'
  'compiled/views/calendar/MissingDateDialogView'
], ($, MissingDateDialogView) ->

  module 'MissingDateDialogView',
    setup: ->
      $('body').append('<label for="date">Section one</label><input type="text" id="date" name="date" />')
      @dialog = new MissingDateDialogView
        validationFn: ->
          invalidFields = []
          $('input[name=date]').each ->
            invalidFields.push($(this)) if $(this).val() == ''
          if invalidFields.length > 0 then invalidFields else true
        success: sinon.spy()

    teardown: ->
      $('input[name=date]').remove()
      $('label[for=date]').remove()
      $('.ui-dialog').remove()

  test 'should display a dialog if the given fields are invalid', ->
    ok @dialog.render()
    ok $('.ui-dialog:visible').length > 0

  test 'it should list the names of the sections w/o dates', ->
    @dialog.render()
    ok $('.ui-dialog').text().match(/Section one/)

  test 'should not display a dialog if the given fields are valid', ->
    $('input[name=date]').val('2013-01-01')
    equal @dialog.render(), false
    equal $('.ui-dialog').length, 0

  test 'should close the dialog on secondary button press', ->
    @dialog.render()
    @dialog.$dialog.find('.btn:not(.btn-primary)').click()
    equal $('.ui-dialog').length, 0

  test 'should run the success callback on on primary button press', ->
    @dialog.render()
    @dialog.$dialog.find('.btn-primary').click()
    ok @dialog.options.success.calledOnce
