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

define(
  ['jsx/gradezilla/shared/AssignmentMuterDialogManager', 'compiled/AssignmentMuter'],
  (AssignmentMuterDialogManager, AssignmentMuter) => {
    const assignment = {foo: 'bar'}
    const url = 'http://example.com'

    QUnit.module('AssignmentMuterDialogManager - constructor')

    test('sets the arguments as properties', function() {
      ;[true, false].forEach(submissionsLoaded => {
        const manager = new AssignmentMuterDialogManager(assignment, url, submissionsLoaded)
        equal(manager.assignment, assignment)
        equal(manager.url, url)
        equal(manager.submissionsLoaded, submissionsLoaded)
      })
    })

    QUnit.module('AssignmentMuterDialogManager - showDialog')

    test('when assignment is muted calls AssignmentMuter.confirmUnmute', function() {
      const confirmUnmuteSpy = this.spy(AssignmentMuter.prototype, 'confirmUnmute')
      assignment.muted = true
      const manager = new AssignmentMuterDialogManager(assignment, url, true)
      manager.showDialog()

      equal(confirmUnmuteSpy.callCount, 1)
    })

    test('when assignment is not muted calls AssignmentMuter.showDialog', function() {
      const showDialogSpy = this.spy(AssignmentMuter.prototype, 'showDialog')
      assignment.muted = false
      const manager = new AssignmentMuterDialogManager(assignment, url, true)
      manager.showDialog()

      equal(showDialogSpy.callCount, 1)
    })

    QUnit.module('AssignmentMuterDialogManager - isDialogEnabled')

    test('return value agrees with submissionsLoaded value', function() {
      ;[true, false].forEach(submissionsLoaded => {
        const manager = new AssignmentMuterDialogManager(assignment, url, submissionsLoaded)
        equal(manager.isDialogEnabled(), submissionsLoaded)
      })
    })
  }
)
