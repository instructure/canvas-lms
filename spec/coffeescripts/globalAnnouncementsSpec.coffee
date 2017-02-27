define [
  'jquery'
  'helpers/fakeENV'
  'global_announcements'
  'jsx/shared/rce/serviceRCELoader'
], ($, fakeENV, globalAnnouncements, serviceRCELoader)->

  QUnit.module "GlobalAnnouncements",
    setup: ->
      fakeENV.setup()
      ENV.RICH_CONTENT_SERVICE_ENABLED = true
      @loadOnTargetStub = sinon.stub(serviceRCELoader, "loadOnTarget")

    teardown: ->
      serviceRCELoader.loadOnTarget.restore()
      $("#fixtures").empty()
      fakeENV.teardown()

  test "loads an editor for every matching node", ->
    html = "<textarea id='a1' class='edit_notification_form'>Announcement 1</textarea>" +
           "<textarea id='a2' class='edit_notification_form'>Announcement 2</textarea>" +
           "<form id='add_notification_form'><textarea id='a3'></textarea></form>"
    $(html).appendTo("#fixtures")
    globalAnnouncements.augmentView()
    ok(@loadOnTargetStub.calledThrice)
