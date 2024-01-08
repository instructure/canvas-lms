/*
 * Copyright (C) 2015 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {chain, difference, find, isEmpty, union} from 'lodash'
import AssignmentOverride from '@canvas/assignments/backbone/models/AssignmentOverride'
import Section from '@canvas/sections/backbone/models/Section'

const TokenActions = {
  // -------------------
  //   Adding Tokens
  // -------------------

  handleTokenAdd(newToken, overridesFromRow, rowKey, dates) {
    this.setOverrideInitializer(rowKey, dates)

    if (newToken.course_section_id) {
      return this.handleSectionTokenAdd(newToken, overridesFromRow)
    } else if (newToken.group_id) {
      return this.handleGroupTokenAdd(newToken, overridesFromRow)
    } else if (newToken.noop_id) {
      return this.handleNoopTokenAdd(newToken, overridesFromRow)
    } else {
      return this.handleStudentTokenAdd(newToken, overridesFromRow)
    }
  },

  // -- Adding Sections --

  handleSectionTokenAdd(token, overridesFromRow) {
    const newOverride = this.newOverrideForRow({
      course_section_id: token.course_section_id,
      title: token.name,
    })

    return union(overridesFromRow, [newOverride])
  },

  // -- Adding Groups --

  handleGroupTokenAdd(token, overridesFromRow) {
    const newOverride = this.newOverrideForRow({
      group_id: token.group_id,
      title: token.name,
    })

    return union(overridesFromRow, [newOverride])
  },

  // -- Adding Students --

  handleStudentTokenAdd(token, overridesFromRow) {
    const existingAdhocOverride = this.findAdhoc(overridesFromRow)

    return existingAdhocOverride
      ? this.addStudentToExistingAdhocOverride(token, existingAdhocOverride, overridesFromRow)
      : this.createNewAdhocOverrideForRow(token, overridesFromRow)
  },

  addStudentToExistingAdhocOverride(newToken, existingOverride, overridesFromRow) {
    const newStudentIds = existingOverride.get('student_ids').concat(newToken.id)
    const newOverride = existingOverride.set('student_ids', newStudentIds)
    newOverride.unset('title', {silent: true})

    return chain(overridesFromRow).difference([existingOverride]).union([newOverride]).value()
  },

  createNewAdhocOverrideForRow(newToken, overridesFromRow) {
    const freshOverride = this.newOverrideForRow({student_ids: []})
    return this.addStudentToExistingAdhocOverride(newToken, freshOverride, overridesFromRow)
  },

  // -- Adding Noop --

  handleNoopTokenAdd(token, overridesFromRow) {
    const newOverride = this.newOverrideForRow({
      noop_id: token.noop_id,
      title: token.name,
    })

    if (token == AssignmentOverride.conditionalRelease) {
      overridesFromRow = this.removeDefaultSection(overridesFromRow)
    }

    return union(overridesFromRow, [newOverride])
  },

  // -------------------
  //  Removing Tokens
  // -------------------

  handleTokenRemove(tokenToRemove, overridesFromRow) {
    if (tokenToRemove.course_section_id) {
      return this.handleSectionTokenRemove(tokenToRemove, overridesFromRow)
    } else if (tokenToRemove.group_id) {
      return this.handleGroupTokenRemove(tokenToRemove, overridesFromRow)
    } else if (tokenToRemove.noop_id) {
      return this.handleNoopTokenRemove(tokenToRemove, overridesFromRow)
    } else {
      return this.handleStudentTokenRemove(tokenToRemove, overridesFromRow)
    }
  },

  handleSectionTokenRemove(tokenToRemove, overridesFromRow) {
    return this.removeForType('course_section_id', tokenToRemove, overridesFromRow)
  },

  handleGroupTokenRemove(tokenToRemove, overridesFromRow) {
    return this.removeForType('group_id', tokenToRemove, overridesFromRow)
  },

  handleNoopTokenRemove(tokenToRemove, overridesFromRow) {
    return this.removeForType('noop_id', tokenToRemove, overridesFromRow)
  },

  removeForType(selector, tokenToRemove, overridesFromRow) {
    const overrideToRemove = find(
      overridesFromRow,
      override => override.get(selector) == tokenToRemove[selector]
    )

    return difference(overridesFromRow, [overrideToRemove])
  },

  removeDefaultSection(overridesFromRow) {
    return this.handleTokenRemove(
      {course_section_id: Section.defaultDueDateSectionID},
      overridesFromRow
    )
  },

  handleStudentTokenRemove(tokenToRemove, overridesFromRow) {
    const adhocOverride = this.findAdhoc(overridesFromRow, tokenToRemove.student_id)
    const newStudentIds = difference(adhocOverride.get('student_ids'), [tokenToRemove.student_id])

    if (isEmpty(newStudentIds)) {
      return difference(overridesFromRow, [adhocOverride])
    }

    const newOverride = adhocOverride.set('student_ids', newStudentIds)
    newOverride.unset('title', {silent: true})
    return chain(overridesFromRow).difference([adhocOverride]).union([newOverride]).value()
  },

  setOverrideInitializer(rowKey, dates) {
    if (!dates) dates = {}

    const date_attrs = {
      due_at: dates.due_at,
      due_at_overridden: !!dates.due_at,
      lock_at: dates.lock_at,
      lock_at_overridden: !!dates.lock_at,
      unlock_at: dates.unlock_at,
      unlock_at_overridden: !!dates.unlock_at,
      rowKey,
    }

    this.newOverrideForRow = function (attributes) {
      const all_attrs = {...date_attrs, ...attributes}
      return new AssignmentOverride(all_attrs)
    }
  },

  // -------------------
  //      Helpers
  // -------------------

  findAdhoc(collection, idToRemove) {
    return find(collection, ov => {
      return (
        !!ov.get('student_ids') && (idToRemove ? ov.get('student_ids').includes(idToRemove) : true)
      )
    })
  },
}

export default TokenActions
