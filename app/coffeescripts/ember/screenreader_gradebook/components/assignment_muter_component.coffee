#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'i18n!sr_gradebook'
  'ember'
  '../../../AssignmentMuter'
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
    attributeBindings: ['type', 'checked', 'ariaLabel:aria-label', 'disabled']

    checked: (->
      this.get('assignment.muted')
    ).property('assignment.muted')

    ariaLabel: (->
      if this.get('assignment.muted')
        I18n.t "assignment_muted", "Click to unmute."
      else
        I18n.t "assignment_unmuted", "Click to mute."
    ).property('assignment.muted')

    disabled: (->
      this.get('assignment.muted') && this.get('assignment.moderated_grading') && \
        !this.get('assignment.grades_published')
    ).property('assignment.muted', 'assignment.moderated_grading', 'assignment.grades_published')

    setup: (->
      if assignment = this.get('assignment')
        url = "#{ENV.GRADEBOOK_OPTIONS.context_url}/assignments/#{assignment.id}/mute"
        @muter = new AssignmentMuter(null, assignment, url, Em.set)
        @muter.show()
    ).observes('assignment').on('init')
