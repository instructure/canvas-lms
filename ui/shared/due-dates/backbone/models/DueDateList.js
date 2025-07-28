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

import AssignmentOverride from '@canvas/assignments/backbone/models/AssignmentOverride'
import Section from '@canvas/sections/backbone/models/Section'

export default class DueDateList {
  constructor(overrides, sections, assignment) {
    this.overrides = overrides
    this.sections = sections
    this.assignment = assignment
    this.courseSectionsLength = this.sections.length
    this.sections.add(Section.defaultDueDateSection())

    this._addOverrideForDefaultSectionIfNeeded()
  }

  getDefaultDueDate = () => {
    return this.overrides.getDefaultDueDate()
  }

  overridesContainDefault = () => {
    return this.overrides.containsDefaultDueDate()
  }

  onlyContainsModuleOverrides = () => {
    return this.overrides.onlyContainsModuleOverrides()
  }

  contextModuleIDs = () => {
    return this.overrides.contextModuleIDs()
  }

  containsSectionsWithoutOverrides = () => {
    if (this.overrides.containsDefaultDueDate()) return false
    if (
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED &&
      ENV.IN_PACED_COURSE &&
      ENV.FEATURES.course_pace_pacing_with_mastery_paths &&
      this.overrides.models.some(({attributes}) => attributes.noop_id === '1')
    ) {
      return false
    }
    return this.sectionsWithOverrides().length < this.courseSectionsLength
  }

  sectionsWithOverrides = () => {
    return this.sections.select(section => {
      let needle
      return (
        ((needle = section.id), this._overrideSectionIDs().includes(needle)) &&
        section.id !== this.defaultDueDateSectionId
      )
    })
  }

  sectionsWithoutOverrides = () => {
    return this.sections.select(section => {
      let needle
      return (
        ((needle = section.id), !this._overrideSectionIDs().includes(needle)) &&
        section.id !== this.defaultDueDateSectionId
      )
    })
  }

  // --- private helpers ---

  _overrideSectionIDs = () => {
    return this.overrides.courseSectionIDs()
  }

  _overrideCourseIds = () => {
    return this.overrides.courseIDs()
  }

  _onlyVisibleToOverrides = () => {
    return this.assignment.isOnlyVisibleToOverrides()
  }

  _addOverrideForDefaultSectionIfNeeded = () => {
    if (
      !this.overrides ||
      this._onlyVisibleToOverrides() ||
      this._overrideCourseIds().some(elem => elem !== undefined)
    )
      return
    const override = AssignmentOverride.defaultDueDate({
      due_at: this.assignment.get('due_at'),
      lock_at: this.assignment.get('lock_at'),
      unlock_at: this.assignment.get('unlock_at'),
    })
    return this.overrides.add(override)
  }
}
DueDateList.prototype.defaultDueDateSectionId = Section.defaultDueDateSectionID
