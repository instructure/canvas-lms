/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import AssignmentFieldValidator from '../AssignentFieldValidator'

describe('Assignment field validators', () => {
  const afv = new AssignmentFieldValidator()

  it('validates points', () => {
    expect(afv.isPointsValid('')).toBeFalsy()
    expect(afv.errorMessage('pointsPossible')).toBeDefined()

    expect(afv.isPointsValid(-1)).toBeFalsy()
    expect(afv.errorMessage('pointsPossible')).toBeDefined()

    expect(afv.isPointsValid('jibberish')).toBeFalsy()
    expect(afv.errorMessage('pointsPossible')).toBeDefined()

    expect(afv.isPointsValid(17)).toBeTruthy()
    expect(afv.errorMessage('pointsPossible')).not.toBeDefined()

    expect(afv.isPointsValid('17')).toBeTruthy()
    expect(afv.errorMessage('pointsPossible')).not.toBeDefined()
  })

  it('validates the name', () => {
    expect(afv.isNameValid('')).toBeFalsy()
    expect(afv.errorMessage('name')).toBeDefined()

    expect(afv.isNameValid()).toBeFalsy()
    expect(afv.errorMessage('name')).toBeDefined()

    expect(afv.isNameValid('  ')).toBeFalsy()
    expect(afv.errorMessage('name')).toBeDefined()

    expect(afv.isNameValid('hello')).toBeTruthy()
    expect(afv.errorMessage('name')).not.toBeDefined()
  })

  it('gets the proper invalid date-time message', () => {
    expect(afv.getInvalidDateTimeMessage({rawDateValue: 'jibberish', rawTimeValue: ''})).toBe(
      'The date is not valid.'
    )

    expect(afv.getInvalidDateTimeMessage({rawDateValue: '', rawTimeValue: 'jibberish'})).toBe(
      'You must provide a date with a time.'
    )

    expect(afv.getInvalidDateTimeMessage({rawDateValue: '', rawTimeValue: ''})).toBe(
      'Invalid date or time'
    )
  })

  const A = '2018-01-02T00:00Z'
  const B = '2018-01-04T00:00Z'
  const C = '2018-01-06T00:00Z'

  it('validates dueAt', () => {
    // the invalid date-time callback from DateTimeInputis routed correctly
    expect(afv.isDueAtValid({rawDateValue: '', rawTimeValue: ''}, 'dueAt')).toBeFalsy()
    expect(afv.errorMessage('dueAt')).toBeDefined()
    expect(afv.errorMessage('unlockAt')).not.toBeDefined()
    expect(afv.errorMessage('lockAt')).not.toBeDefined()

    // due before unlock
    expect(afv.isDueAtValid(A, 'dueAt', {unlockAt: B, lockAt: C})).toBeFalsy()
    expect(afv.errorMessage('dueAt')).toBeDefined()
    expect(afv.errorMessage('unlockAt')).not.toBeDefined()
    expect(afv.errorMessage('lockAt')).not.toBeDefined()

    // due after lock
    expect(afv.isDueAtValid(C, 'dueAt', {unlockAt: A, lockAt: B})).toBeFalsy()
    expect(afv.errorMessage('dueAt')).toBeDefined()
    expect(afv.errorMessage('unlockAt')).not.toBeDefined()
    expect(afv.errorMessage('lockAt')).not.toBeDefined()

    expect(afv.isDueAtValid(B, 'dueAt', {unlockAt: A, lockAt: C})).toBeTruthy()
    expect(afv.errorMessage('dueAt')).not.toBeDefined()
    expect(afv.errorMessage('unlockAt')).not.toBeDefined()
    expect(afv.errorMessage('lockAt')).not.toBeDefined()
  })

  it('validates unlockAt', () => {
    // the invalid date-time callback from DateTimeInputis routed correctly
    expect(afv.isUnlockAtValid({rawDateValue: '', rawTimeValue: ''}, 'unlockAt')).toBeFalsy()
    expect(afv.errorMessage('dueAt')).not.toBeDefined()
    expect(afv.errorMessage('unlockAt')).toBeDefined()
    expect(afv.errorMessage('lockAt')).not.toBeDefined()

    // unlock before due
    expect(afv.isUnlockAtValid(B, 'unlockAt', {dueAt: A, lockAt: C})).toBeFalsy()
    expect(afv.errorMessage('dueAt')).not.toBeDefined()
    expect(afv.errorMessage('unlockAt')).toBeDefined()
    expect(afv.errorMessage('lockAt')).not.toBeDefined()

    // unlock after lock
    expect(afv.isUnlockAtValid(B, 'unlockAt', {dueAt: C, lockAt: A})).toBeFalsy()
    expect(afv.errorMessage('dueAt')).not.toBeDefined()
    expect(afv.errorMessage('unlockAt')).toBeDefined()
    expect(afv.errorMessage('lockAt')).not.toBeDefined()

    expect(afv.isUnlockAtValid(A, 'unlockAt', {dueAt: B, lockAt: C})).toBeTruthy()
    expect(afv.errorMessage('dueAt')).not.toBeDefined()
    expect(afv.errorMessage('unlockAt')).not.toBeDefined()
    expect(afv.errorMessage('lockAt')).not.toBeDefined()
  })

  it('validates lockAt', () => {
    // the invalid date-time callback from DateTimeInputis routed correctly
    expect(afv.isLockAtValid({rawDateValue: '', rawTimeValue: ''}, 'lockAt')).toBeFalsy()
    expect(afv.errorMessage('dueAt')).not.toBeDefined()
    expect(afv.errorMessage('unlockAt')).not.toBeDefined()
    expect(afv.errorMessage('lockAt')).toBeDefined()

    // lock before due
    expect(afv.isLockAtValid(B, 'lockAt', {dueAt: C, unlockAt: A})).toBeFalsy()
    expect(afv.errorMessage('dueAt')).not.toBeDefined()
    expect(afv.errorMessage('unlockAt')).not.toBeDefined()
    expect(afv.errorMessage('lockAt')).toBeDefined()

    // lock before unlock
    expect(afv.isLockAtValid(B, 'lockAt', {dueAt: A, unlockAt: C})).toBeFalsy()
    expect(afv.errorMessage('dueAt')).not.toBeDefined()
    expect(afv.errorMessage('unlockAt')).not.toBeDefined()
    expect(afv.errorMessage('lockAt')).toBeDefined()

    expect(afv.isLockAtValid(C, 'lockAt', {dueAt: B, unlockAt: A})).toBeTruthy()
    expect(afv.errorMessage('dueAt')).not.toBeDefined()
    expect(afv.errorMessage('unlockAt')).not.toBeDefined()
    expect(afv.errorMessage('lockAt')).not.toBeDefined()
  })

  it('returns the invalid messages collection', () => {
    expect(afv.isNameValid('')).toBeFalsy()
    expect(Object.keys(afv.invalidFields())).toContain('name')
  })

  it('routes to the correct validator', () => {
    expect(afv.validate('foo.bar.name', '', {})).toBeFalsy()
    expect(afv.errorMessage('name')).toBeDefined()
  })

  it('returns true for no validator', () => {
    expect(afv.validate('foo')).toBeTruthy()
  })
})
