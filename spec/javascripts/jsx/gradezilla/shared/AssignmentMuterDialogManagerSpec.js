/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import AssignmentMuterDialogManager from 'jsx/gradezilla/shared/AssignmentMuterDialogManager'
import AssignmentMuter from 'compiled/AssignmentMuter'

QUnit.module('AssignmentMuterDialogManager', suiteHooks => {
  const url = 'http://example.com'

  let assignment
  let submissionsLoaded

  suiteHooks.beforeEach(() => {
    assignment = {anonymous_grading: false, grades_published: true, muted: true}
    submissionsLoaded = false
  })

  function createManager() {
    return new AssignmentMuterDialogManager(
      assignment,
      url,
      submissionsLoaded
    )
  }

  QUnit.module('#assignment', () => {
    test('is set to the "assignment" constructor argument', () => {
      equal(createManager().assignment, assignment)
    })
  })

  QUnit.module('#url', () => {
    test('is set to the "url" constructor argument', () => {
      equal(createManager().url, url)
    })
  })

  QUnit.module('#submissionsLoaded', () => {
    test('is set to the "submissionsLoaded" constructor argument', () => {
      equal(createManager().submissionsLoaded, submissionsLoaded)
    })
  })

  QUnit.module('#showDialog()', hooks => {
    hooks.beforeEach(() => {
      sinon.spy(AssignmentMuter.prototype, 'confirmUnmute')
      sinon.spy(AssignmentMuter.prototype, 'showDialog')
    })

    hooks.afterEach(() => {
      AssignmentMuter.prototype.confirmUnmute.restore()
      AssignmentMuter.prototype.showDialog.restore()
    })

    test('shows the Unmute dialog when the assignment is muted', () => {
      assignment.muted = true
      createManager().showDialog()
      strictEqual(AssignmentMuter.prototype.confirmUnmute.callCount, 1)
    })

    test('shows the Mute dialog when the assignment is unmuted', () => {
      assignment.muted = false
      createManager().showDialog()
      strictEqual(AssignmentMuter.prototype.showDialog.callCount, 1)
    })
  })

  QUnit.module('#isDialogEnabled()', () => {
    test('returns true when submissions are loaded', () => {
      submissionsLoaded = true
      strictEqual(createManager().isDialogEnabled(), true)
    })

    test('returns false when submissions are still loading', () => {
      submissionsLoaded = false
      strictEqual(createManager().isDialogEnabled(), false)
    })

    test('returns false when the assignment is moderated and grades have not been published', () => {
      assignment.grades_published = false
      assignment.moderated_grading = true
      submissionsLoaded = true
      strictEqual(createManager().isDialogEnabled(), false)
    })

    test('returns true for moderated assignments when grades have been published', () => {
      assignment.grades_published = true
      assignment.moderated_grading = true
      submissionsLoaded = true
      strictEqual(createManager().isDialogEnabled(), true)
    })

    test('returns true for moderated assignments when not muted', () => {
      assignment.grades_published = false
      assignment.moderated_grading = true
      assignment.muted = false
      submissionsLoaded = true
      strictEqual(createManager().isDialogEnabled(), true)
    })

    test('returns true for assignments when not moderated', () => {
      assignment.grades_published = true
      assignment.moderated_grading = false
      submissionsLoaded = true
      strictEqual(createManager().isDialogEnabled(), true)
    })
  })
})
