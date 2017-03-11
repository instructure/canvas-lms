define [
  'jquery'
  'compiled/behaviors/elementToggler'
], ($, elementToggler)->

  QUnit.module 'elementToggler',
    teardown: ->
      el?.remove() for el in [@$trigger, @$otherTrigger, @$target, @$target1, @$target2]
      $("#fixtures").empty()

  test 'handles data-html-while-target-shown', ->
    @$trigger = $('<a href="#" class="element_toggler" role="button"
                      data-html-while-target-shown="Hide Thing"
                      aria-controls="thing">Show Thing</a>').appendTo('#fixtures')

    @$otherTrigger = $('<a class="element_toggler"
                           data-html-while-target-shown="while shown"
                           aria-controls="thing">while hidden</a>').appendTo('#fixtures')

    @$target = $('<div id="thing" tabindex="-1" role="region" style="display:none">
                    Here is a bunch more info about "thing"
                  </div>').appendTo('#fixtures')

    # click to show it
    @$trigger.click()
    msg = 'Handles `data-html-while-target-shown`'
    equal @$trigger.text(), 'Hide Thing', msg
    equal @$otherTrigger.text(), 'while shown', msg
    ok @$trigger.is(':visible'), 'does not hide trigger unless `data-hide-while-target-shown` is specified'

    # click to hide it
    @$trigger.click()
    ok @$target.is('[aria-expanded=false]:hidden'), "target is hidden"
    equal @$trigger.text(), 'Show Thing', msg
    equal @$otherTrigger.text(), 'while hidden', msg

  test 'handles data-hide-while-target-shown', ->
    @$trigger = $('<a href="#"
                      class="element_toggler"
                      data-hide-while-target-shown="true"
                      aria-controls="thing">Show Thing, then hide me</a>').appendTo('#fixtures')

    @$otherTrigger = $('<a class="element_toggler"
                           data-hide-while-target-shown=true
                           aria-controls="thing">also hide me</a>').appendTo('#fixtures')

    @$target = $('<div id="thing"
                       tabindex="-1"
                       role="region"
                       style="display:none">blah</div>').appendTo('#fixtures')

    # click to show it
    @$trigger.click()
    ok @$target.is('[aria-expanded=true]:visible'), "target is shown"

    msg = 'Does not change text unless `data-html-while-target-shown` is specified'
    equal $.trim(@$trigger.text()), 'Show Thing, then hide me', msg

    msg = 'Handles `data-hide-while-target-shown`'
    ok @$trigger.is(':hidden'), msg
    ok @$otherTrigger.is(':hidden'), msg

    # click to hide it
    @$trigger.click()
    ok @$target.is('[aria-expanded=false]:hidden'), "target is hidden"
    ok @$trigger.is(':visible'), msg
    ok @$otherTrigger.is(':visible'), msg

  test 'handles dialogs', ->
    @$trigger = $('<button class="element_toggler"
                           aria-controls="thing">Show Thing Dialog</button>').appendTo('#fixtures')

    @$target = $("""
      <form id="thing" data-turn-into-dialog='{"width":450,"modal":true}' style="display:none">
        This will pop up as a dilog when you click the button and pass along the
        data-turn-into-dialog options.  then it will pass it through fixDialogButtons
        to turn the buttons in your markup into proper dialog buttons
        (look at fixDialogButtons to see what it does)
        <div class="button-container">
          <button type="submit">This will Submit the form</button>
          <a class="btn dialog_closer">This will cause the dialog to close</a>
        </div>
      </form>
    """).appendTo('#fixtures')

    # click to show it
    msg = "target pops up as a dialog"
    spy = @spy $.fn, 'fixDialogButtons'

    @$trigger.click()
    ok @$target.is(':ui-dialog:visible'), msg

    ok spy.thisValues[0].is(@$target), 'calls fixDialogButton on @$trigger'

    msg = "handles `data-turn-into-dialog` options correctly"
    equal @$target.dialog('option', 'width'), 450, msg
    equal @$target.dialog('option', 'modal'), true, msg


    msg = "make sure clicking on converted ui-dialog-buttonpane .ui-button causes submit handler to be called on form"
    submitWasCalled = false
    @$target.submit -> submitWasCalled = true; false
    $submitButton = @$target.dialog('widget').find('.ui-dialog-buttonpane .ui-button:contains("This will Submit the form")')
    $submitButton.click()
    ok submitWasCalled, msg
    equal @$target.dialog('isOpen'), true, "doesnt cause dialog to hide"

    msg = 'make sure clicking on the .dialog_closer causes dialog to close'
    $closer = @$target.dialog('widget').find('.ui-dialog-buttonpane .ui-button:contains("This will cause the dialog to close")')
    $closer.click()
    equal @$target.dialog('isOpen'), false, msg

    # open it back up
    @$trigger.click()
    equal @$target.dialog('isOpen'), true

    # and close it again
    @$trigger.click()
    equal @$target.dialog('isOpen'), false

  test 'checkboxes can be used as trigger', ->
    @$trigger = $('<input type="checkbox" class="element_toggler" aria-controls="thing">').appendTo('#fixtures')

    @$target = $('<div id="thing" style="display:none">thing</div>').appendTo('#fixtures')

    @$trigger.prop('checked', true).trigger('change')
    ok @$target.is(':visible'), "target is shown"

    @$trigger.prop('checked', false).trigger('change')
    ok @$target.is(':hidden'), "target is hidden"

  test 'toggles multiple elements separated by spaces', ->
    @$trigger = $('<input type="checkbox" class="element_toggler" aria-controls="one two" />').appendTo('#fixtures')
    @$target1 = $('<div id="one" style="display: none;">one</div>').appendTo('#fixtures')
    @$target2 = $('<div id="two" style="display: none;">two</div>').appendTo('#fixtures')
    @$trigger.prop('checked', true).trigger('change')


    ok @$target1.is(':visible'), 'first target is shown'
    ok @$target2.is(':visible'), 'second target is shown'
