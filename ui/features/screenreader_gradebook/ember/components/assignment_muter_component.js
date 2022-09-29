//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import {useScope as useI18nScope} from '@canvas/i18n'
import Ember from 'ember'
import AssignmentMuter from '../../jquery/AssignmentMuter'

const I18n = useI18nScope('sr_gradebook')

// http://emberjs.com/guides/components/
// http://emberjs.com/api/classes/Ember.Component.html

const AssignmentMuterComponent = Ember.Component.extend({
  click(e) {
    e.preventDefault()
    if (this.get('assignment.muted')) {
      this.unmute()
    } else {
      this.mute()
    }
  },
  mute() {
    return AssignmentMuter.prototype.showDialog.call(this.muter)
  },
  unmute() {
    return AssignmentMuter.prototype.confirmUnmute.call(this.muter)
  },

  tagName: 'input',
  type: 'checkbox',
  attributeBindings: ['type', 'checked', 'ariaLabel:aria-label', 'disabled'],

  checked: function () {
    return this.get('assignment.muted')
  }.property('assignment.muted'),

  ariaLabel: function () {
    if (this.get('assignment.muted')) {
      return I18n.t('assignment_muted', 'Click to unmute.')
    } else {
      return I18n.t('assignment_unmuted', 'Click to mute.')
    }
  }.property('assignment.muted'),

  disabled: function () {
    return (
      this.get('assignment.muted') &&
      this.get('assignment.moderated_grading') &&
      !this.get('assignment.grades_published')
    )
  }.property('assignment.muted', 'assignment.moderated_grading', 'assignment.grades_published'),

  setup: function () {
    let assignment
    if ((assignment = this.get('assignment'))) {
      const url = `${ENV.GRADEBOOK_OPTIONS.context_url}/assignments/${assignment.id}/mute`
      this.muter = new AssignmentMuter(null, assignment, url, Ember.set)
      this.muter.show()
    }
  }
    .observes('assignment')
    .on('init'),
})

export default AssignmentMuterComponent
