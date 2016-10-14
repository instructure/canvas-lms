define [
  'select_content_dialog',
  'jquery',
  'helpers/fakeENV'
], (SelectContentDialog, $, fakeENV) ->

  fixtures = null
  clickEvent = {}

  module "SelectContentDialog",
    setup: ->
      fixtures = document.getElementById('fixtures')
      fixtures.innerHTML = '<div id="context_external_tools_select">
      <div class="tools"><div id="test-tool" class="tool resource_selection"></div></div></div>'

      $l = $(document.getElementById('test-tool'))
      clickEvent = {
        originalEvent: MouseEvent,
        type: "click",
        timeStamp: 1433863761376,
        jQuery17209791898143012077: true,
        preventDefault: ()->
      }
      $l.data('tool', {
        placements: {
          resource_selection: {}
        }
      })
    teardown: ->
      $(window).off('beforeunload')
      clickEvent = {}
      fixtures.innerHTML = ""

  test "it creates a confirm alert before closing the modal", ()->
    l = document.getElementById('test-tool')
    @stub(window, "confirm", -> true )
    SelectContentDialog.Events.onContextExternalToolSelect.bind(l)(clickEvent)
    $dialog = $("#resource_selection_dialog")
    $dialog.dialog('close')
    ok window.confirm.called

  test "it removes the confim alert if a selection is passed back", ()->
    l = document.getElementById('test-tool')
    @mock(window).expects("confirm").never()
    SelectContentDialog.Events.onContextExternalToolSelect.bind(l)(clickEvent)
    $dialog = $("#resource_selection_dialog")
    selectionEvent = $.Event( "selection", { contentItems: [{
      "@type": 'LtiLinkItem',
      url: 'http://canvas.instructure.com/test',
      placementAdvice: {
        presentationDocumentTarget: ""
      }
    }] } )
    $dialog.trigger(selectionEvent)
