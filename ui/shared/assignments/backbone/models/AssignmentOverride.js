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
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import Backbone from '@canvas/backbone'
import {extend as lodashExtend} from 'lodash'
import Section from '@canvas/sections/backbone/models/Section'
import {useScope as useI18nScope} from '@canvas/i18n'
import {shimGetterShorthand} from '@canvas/util/legacyCoffeesScriptHelpers'

let AssignmentOverride

const I18n = useI18nScope('assignmentOverride')

export default AssignmentOverride = (function () {
  AssignmentOverride = class AssignmentOverride extends Backbone.Model {
    constructor(...args) {
      super(...args)
      this.isBlank = this.isBlank.bind(this)
      this.getCourseSectionID = this.getCourseSectionID.bind(this)
      this.representsDefaultDueDate = this.representsDefaultDueDate.bind(this)
      this.combinedDates = this.combinedDates.bind(this)
    }

    static initClass() {
      this.prototype.defaults = {
        due_at_overridden: true,
        due_at: null,
        all_day: false,
        all_day_date: null,

        unlock_at_overridden: true,
        unlock_at: null,

        lock_at_overridden: true,
        lock_at: null,
      }

      this.conditionalRelease = shimGetterShorthand(
        {noop_id: '1'},
        {
          name() {
            return I18n.t('Mastery Paths')
          },
        }
      )
    }

    initialize() {
      super.initialize(...arguments)
      return this.on('change:course_section_id', this.clearID, this)
    }

    // This method exists because the api cannot currently update the
    // course_section_id for an assignment override.
    clearID() {
      return this.set('id', undefined)
    }

    parse({assignment_override}) {
      return assignment_override
    }

    // Re-apply the original assignment_override namespace
    // since rails is expecting it.
    toJSON() {
      return {assignment_override: super.toJSON(...arguments)}
    }

    static defaultDueDate(options) {
      if (options == null) {
        options = {}
      }
      const opts = lodashExtend(options, {course_section_id: Section.defaultDueDateSectionID})
      return new AssignmentOverride(opts)
    }

    isBlank() {
      return this.get('due_at') == null
    }

    getCourseSectionID() {
      return this.get('course_section_id')
    }

    representsDefaultDueDate() {
      return this.getCourseSectionID() === Section.defaultDueDateSectionID
    }

    combinedDates() {
      // using this as a key to sort overrides
      // into rows in the due date picker
      const override_id = this.get('id') === undefined ? null : this.get('id')
      return `${this.get('due_at') + this.get('unlock_at') + this.get('lock_at') + override_id}`
    }
  }
  AssignmentOverride.initClass()
  return AssignmentOverride
})()
