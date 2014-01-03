define [
  'compiled/views/conferences/ConferenceView'
  'jst/conferences/concludedConference'
], (ConferenceView, template) ->

  class ConcludedConferenceView extends ConferenceView
    template: template
