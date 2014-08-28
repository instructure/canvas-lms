define [
  'i18n!sr_gradebook'
  'ember'
  'compiled/AssignmentMuter'
  ], (I18n, Ember, AssignmentMuter) ->

  # http://emberjs.com/guides/components/
  # http://emberjs.com/api/classes/Ember.Component.html

  AssignmentMuterComponent = Ember.Component.extend

    click: (e) ->
      e.preventDefault()
      if this.get('assignment.muted') then @unmute() else @mute()
    mute: -> AssignmentMuter::showDialog.call @muter
    unmute: -> AssignmentMuter::confirmUnmute.call @muter

    tagName: 'input'
    type: 'checkbox'
    attributeBindings: ['type', 'checked', 'ariaLabel:aria-label']

    checked: (->
      this.get('assignment.muted')
    ).property('assignment.muted')

    ariaLabel: (->
      if this.get('assignment.muted')
        I18n.t "assignment_muted", "Click to unmute."
      else
        I18n.t "assignment_unmuted", "Click to mute."
    ).property('assignment.muted')

    setup: (->
      if assignment = this.get('assignment')
        url = "#{ENV.GRADEBOOK_OPTIONS.context_url}/assignments/#{assignment.id}/mute"
        @muter = new AssignmentMuter(null, assignment, url, Em.set)
    ).observes('assignment').on('init')
