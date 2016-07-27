define ['collaborations'], (collaborations) ->

  oldAjaxJSON = null
  module "Collaborations",
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
      $("#delete_collaboration_dialog").remove()
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

  test "returns a collaboration url", ->
    url = collaborations.Util.collaborationUrl(1)
    equal url, window.location.toString() + "/1"

  test "it calls updateCollaboration when a service id is in the data parameter", ->
    @stub(collaborations.Events, 'updateCollaboration')
    collaborations.Events.onExternalContentReady({}, {service_id: 1, contentItems: {}})
    equal collaborations.Events.updateCollaboration.callCount, 1

  test "it calls createCollaboration", ->
    @stub(collaborations.Events, 'createCollaboration')
    collaborations.Events.onExternalContentReady({}, {contentItems: {}})
    equal collaborations.Events.createCollaboration.callCount, 1

  test "it makes an ajax request to the correct update endpoint", ->
    dom = $('<div class="collaboration_1"><a class="title" href="http://url/"></a></div>')
    $("#fixtures").append(dom)
    $.ajaxJSON = (url, method, data, callback)->
      equal url, 'http://url/'
    collaborations.Events.onExternalContentReady({}, {service_id: 1, contentItems: {}})