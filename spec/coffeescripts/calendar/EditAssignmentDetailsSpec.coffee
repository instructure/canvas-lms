define [
  'jquery'
  'compiled/calendar/EditAssignmentDetails'
  'timezone'
  'vendor/timezone/America/Detroit'
  'vendor/timezone/fr_FR'
  'helpers/I18nStubber'
], ($, EditAssignmentDetails, tz, detroit, french, I18nStubber) ->

  module "EditAssignmentDetails",
    setup: ->
      @snapshot = tz.snapshot()
      @$holder = $('<table />').appendTo(document.getElementById("fixtures"))
      @event =
        possibleContexts: -> []
        isNewEvent: -> true
        startDate: -> $.fudgeDateForProfileTimezone('2015-08-07T17:00:00Z')
        allDay: false

    teardown: ->
      # tick past any remaining errorBox fade-ins
      @$holder.detach()
      document.getElementById("fixtures").innerHTML = ""
      tz.restore(@snapshot)

  test "should initialize input with start date and time", ->
    instance = new EditAssignmentDetails('#fixtures', @event, null, null)
    $field = instance.$form.find(".datetime_field")
    equal $field.val(), "Aug 7, 2015 5:00pm"

  test "should have blank input when no start date", ->
    @event.startDate = -> null
    instance = new EditAssignmentDetails('#fixtures', @event, null, null)
    $field = instance.$form.find(".datetime_field")
    equal $field.val(), ""

  test "should include start date only if all day", ->
    @event.allDay = true
    instance = new EditAssignmentDetails('#fixtures', @event, null, null)
    $field = instance.$form.find(".datetime_field")
    equal $field.val(), "Aug 7, 2015"

  test "should treat start date as fudged", ->
    tz.changeZone(detroit, 'America/Detroit')
    instance = new EditAssignmentDetails('#fixtures', @event, null, null)
    $field = instance.$form.find(".datetime_field")
    equal $field.val(), "Aug 7, 2015 1:00pm"

  test "should localize start date", ->
    I18nStubber.pushFrame()
    tz.changeLocale(french, 'fr_FR')
    I18nStubber.setLocale 'fr_FR'
    I18nStubber.stub 'fr_FR', 'date.formats.full': '%-d %b %Y %-k:%M'

    instance = new EditAssignmentDetails('#fixtures', @event, null, null)
    $field = instance.$form.find(".datetime_field")
    equal $field.val(), "7 août 2015 17:00"

    I18nStubber.popFrame()
