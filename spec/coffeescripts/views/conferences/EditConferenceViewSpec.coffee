define [
  'compiled/views/conferences/EditConferenceView'
  'timezone'
  'vendor/timezone/fr_FR'
  'helpers/I18nStubber'
  'helpers/fakeENV'
], (EditConferenceView, tz, french, I18nStubber, fakeENV) ->
  module 'EditConferenceView',
    setup: ->
      @snapshot = tz.snapshot()
      @view = new EditConferenceView

    teardown: ->
      tz.restore(@snapshot)

  test 'updateConferenceUserSettingDetailsForConference localizes values for datepicker settings', ->
    tz.changeLocale(french, 'fr_FR')
    I18nStubber.pushFrame()
    I18nStubber.setLocale 'fr_FR'
    I18nStubber.stub 'fr_FR', 'date.formats.full_with_weekday': '%a %-d %b, %Y %-k:%M'

    datepickerSetting = {field: 'datepickerSetting', type: 'date_picker'}
    conferenceData = {user_settings: {datepickerSetting: '2015-08-07T17:00:00Z'}}
    fakeENV.setup(conference_type_details: [{settings: [datepickerSetting]}])
    @view.updateConferenceUserSettingDetailsForConference(conferenceData)
    equal datepickerSetting.value, 'ven. 7 août, 2015 17:00'

    fakeENV.teardown()
    I18nStubber.popFrame()
