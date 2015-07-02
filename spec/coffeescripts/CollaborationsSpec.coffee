define ['collaborations'], (collaborations) ->

  oldAjaxJSON = null
  module "Events -> onDelete",
    setup: ->
      oldAjaxJSON = $.ajaxJSON
      link= $("<a></a>")
      link.addClass("delete_collaboration_link")
      link.attr('href', "http://test.com")
      dialog = $('<div id=delete_collaboration_dialog></div>').data('collaboration', link)
      dialog.dialog
        width: 550
        height: 500
        resizable: false
      dom = $("<div></div>")
      dom.append(dialog)
      $("#fixtures").append(dom)

    teardown: ->
      $("#fixtures").empty()
      $.ajaxJSON = oldAjaxJSON

  test "shows a flash message when deletion is complete", ->
    @spy($, 'screenReaderFlashMessage')
    e = {
      originalEvent: MouseEvent,
      type: "click",
      timeStamp: 1433863761376,
      jQuery17209791898143012077: true
    }
    $.ajaxJSON = (url, method, data, callback)->
      responseData = {}
      callback.call(responseData)
    collaborations.Events.onDelete(e)
    equal $.screenReaderFlashMessage.callCount, 1
