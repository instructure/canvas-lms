/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import Submission from 'compiled/models/Submission'

QUnit.module('Submission')

QUnit.module('Submission#isGraded')

test('returns false if grade is null', () => {
  const submission = new Submission({grade: null})
  deepEqual(submission.isGraded(), false)
})

test('returns true if grade is present', () => {
  const submission = new Submission({grade: 'A'})
  deepEqual(submission.isGraded(), true)
})

QUnit.module('Submission#hasSubmission')

test('returns false if submission type is null', () => {
  const submission = new Submission({submission_type: null})
  deepEqual(submission.hasSubmission(), false)
})

test('returns true if submission has a submission type', () => {
  const submission = new Submission({submission_type: 'online'})
  deepEqual(submission.hasSubmission(), true)
})
