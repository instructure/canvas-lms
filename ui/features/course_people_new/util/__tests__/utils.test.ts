/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {secondsToTime, sortRoles, getRoleName} from '../utils'
import type {EnvRole} from '../../types'
import {
  NO_PERMISSIONS,
  ACCOUNT_MEMBERSHIP,
  TEACHER_ENROLLMENT,
  STUDENT_ENROLLMENT,
  TA_ENROLLMENT,
  OBSERVER_ENROLLMENT,
  DESIGNER_ENROLLMENT,
  ACCOUNT_ADMIN,
  TEACHER_ROLE,
  STUDENT_ROLE,
  TA_ROLE,
  OBSERVER_ROLE,
  DESIGNER_ROLE,
} from '../constants'

describe('utils', () => {
  describe('secondsToTime', () => {
    it('less than one minute', () => {
      expect(secondsToTime(0)).toBe('00:00')
      expect(secondsToTime(1)).toBe('00:01')
      expect(secondsToTime(11)).toBe('00:11')
    })

    it('exactly one minute and one hour', () => {
      expect(secondsToTime(60)).toBe('01:00')
      expect(secondsToTime(3600)).toBe('01:00:00')
    })

    it('less than one hour', () => {
      expect(secondsToTime(61)).toBe('01:01')
      expect(secondsToTime(900)).toBe('15:00')
      expect(secondsToTime(3599)).toBe('59:59')
    })

    it('less than 100 hours', () => {
      expect(secondsToTime(32400)).toBe('09:00:00')
      expect(secondsToTime(359999)).toBe('99:59:59')
    })

    it('more than 100 hours', () => {
      expect(secondsToTime(360000)).toBe('100:00:00')
      expect(secondsToTime(478861)).toBe('133:01:01')
      expect(secondsToTime(8000542)).toBe('2222:22:22')
    })
  })

  describe('sortRoles', () => {
    it('sorts roles according to predefined order', () => {
      const roles: Partial<EnvRole>[] = [
        {base_role_name: OBSERVER_ENROLLMENT, name: 'Observer'},
        {base_role_name: DESIGNER_ENROLLMENT, name: 'Designer'},
        {base_role_name: NO_PERMISSIONS, name: 'No Permissions'},
        {base_role_name: ACCOUNT_MEMBERSHIP, name: 'Account Member'},
        {base_role_name: TEACHER_ENROLLMENT, name: 'Teacher'},
        {base_role_name: STUDENT_ENROLLMENT, name: 'Student'},
        {base_role_name: TA_ENROLLMENT, name: 'TA'},
      ]

      const sorted = sortRoles(roles as EnvRole[])
      expect(sorted.map(r => r.name)).toEqual([
        'No Permissions',
        'Account Member',
        'Student',
        'TA',
        'Teacher',
        'Designer',
        'Observer'
      ])
    })

    it('puts account admin role first', () => {
      const roles: Partial<EnvRole>[] = [
        {base_role_name: TEACHER_ENROLLMENT, name: 'Teacher'},
        {base_role_name: ACCOUNT_MEMBERSHIP, name: ACCOUNT_ADMIN},
        {base_role_name: STUDENT_ENROLLMENT, name: 'Student'},
      ]

      const sorted = sortRoles(roles as EnvRole[])
      expect(sorted.map(r => r.name)).toEqual([ACCOUNT_ADMIN, 'Student', 'Teacher'])
    })

    it('sorts alphabetically within same base role type', () => {
      const roles: Partial<EnvRole>[] = [
        {base_role_name: TEACHER_ENROLLMENT, name: 'Senior Teacher'},
        {base_role_name: TEACHER_ENROLLMENT, name: 'Assistant Teacher'},
        {base_role_name: STUDENT_ENROLLMENT, name: 'Student'},
      ]

      const sorted = sortRoles(roles as EnvRole[])
      expect(sorted.map(r => r.name)).toEqual(['Student', 'Assistant Teacher', 'Senior Teacher'])
    })
  })

  describe('getRoleName', () => {
    it('returns translated name for standard SIS roles', () => {
      expect(getRoleName(TEACHER_ROLE)).toBe('Teacher')
      expect(getRoleName(STUDENT_ROLE)).toBe('Student')
      expect(getRoleName(TA_ROLE)).toBe('TA')
      expect(getRoleName(OBSERVER_ROLE)).toBe('Observer')
      expect(getRoleName(DESIGNER_ROLE)).toBe('Designer')
    })

    it('returns original name for custom roles', () => {
      const customRole = 'Custom Teaching Assistant'
      expect(getRoleName(customRole)).toBe(customRole)
    })
  })
})
