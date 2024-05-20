/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import moment from 'moment'
import {defaultState} from '../../react/settingsReducer'
import {
  calculatePanelHeight,
  convertFriendlyDatetimeToUTC,
  convertModuleSettingsForApi,
} from '../miscHelpers'
import type {Requirement} from '../../react/types'

describe('calculatePanelHeight', () => {
  it('computes the correct height when withinTabs is true', () => {
    expect(calculatePanelHeight(true)).toBe('calc(100vh - 127.5px)')
  })

  it('computes the correct height when withinTabs is false', () => {
    expect(calculatePanelHeight(false)).toBe('calc(100vh - 79.5px)')
  })
})

describe('convertFriendlyDatetimeToUTC', () => {
  beforeAll(() => {
    window.ENV.TIMEZONE = 'America/Denver'
    moment.tz.setDefault('America/Denver')
  })

  it('returns undefined if input is undefined, null, or empty', () => {
    expect(convertFriendlyDatetimeToUTC(undefined)).toBe(undefined)
    expect(convertFriendlyDatetimeToUTC(null)).toBe(undefined)
    expect(convertFriendlyDatetimeToUTC('')).toBe(undefined)
  })

  it('returns a UTC date string if input is a date-like string', () => {
    expect(convertFriendlyDatetimeToUTC('Aug 2, 2023 at 12am')).toBe('2023-08-02T06:00:00.000Z')
    expect(convertFriendlyDatetimeToUTC('Jan 8, 2023')).toBe('2023-01-08T07:00:00.000Z')
    expect(convertFriendlyDatetimeToUTC('May 10, 2022 at 1:44pm')).toBe('2022-05-10T19:44:00.000Z')
  })
})

describe('convertModuleSettingsForApi', () => {
  const moduleSettings = {
    ...defaultState,
    moduleName: 'Module 1',
    lockUntilChecked: true,
    unlockAt: '2023-08-02T06:00:00.000Z',
    prerequisites: [
      {id: '1', name: 'Week 1'},
      {id: '2', name: 'Week 2'},
    ],
    requirements: [
      {type: 'view', id: '1', name: 'Mod 1', resource: 'externalUrl'},
      {type: 'mark', id: '2', name: 'Mod 2', resource: 'page'},
      {
        type: 'submit',
        id: '3',
        name: 'Mod 3',
        resource: 'assignment',
        minimumScore: '50',
        pointsPossible: '100',
      },
      {
        type: 'score',
        id: '4',
        name: 'Mod 4',
        resource: 'quiz',
        minimumScore: '50',
        pointsPossible: '100',
      },
      {type: 'contribute', id: '5', name: 'Mod 5', resource: 'discussion'},
    ] as Requirement[],
    requirementCount: 'all' as const,
    requireSequentialProgress: false,
    publishFinalGrade: true,
  }

  it('converts the module settings to the format expected by the API', () => {
    expect(convertModuleSettingsForApi(moduleSettings)).toEqual({
      context_module: {
        name: 'Module 1',
        unlock_at: '2023-08-02T06:00:00.000Z',
        prerequisites: 'module_1,module_2',
        completion_requirements: {
          1: {min_score: '', type: 'must_view'},
          2: {min_score: '', type: 'must_mark_done'},
          3: {min_score: '', type: 'must_submit'},
          4: {min_score: '50', type: 'min_score'},
          5: {min_score: '', type: 'must_contribute'},
        },
        requirement_count: '',
        require_sequential_progress: false,
        publish_final_grade: true,
      },
    })
  })

  it('excludes unlockAt if lockUntilChecked is false', () => {
    const formattedSettings = convertModuleSettingsForApi({
      ...moduleSettings,
      lockUntilChecked: false,
    })
    expect(formattedSettings.context_module.unlock_at).toBe(null)
  })

  it('has requirement_count of 1 if requirementCount is one', () => {
    const formattedSettings = convertModuleSettingsForApi({
      ...moduleSettings,
      requirementCount: 'one',
    })
    expect(formattedSettings.context_module.requirement_count).toBe('1')
  })

  it('has require_sequential_progress of true if count is all and RSP is true', () => {
    const formattedSettings = convertModuleSettingsForApi({
      ...moduleSettings,
      requirementCount: 'all',
      requireSequentialProgress: true,
    })
    expect(formattedSettings.context_module.require_sequential_progress).toBe(true)
  })

  it('has require_sequential_progress of false if count is one and RSP is true', () => {
    const formattedSettings = convertModuleSettingsForApi({
      ...moduleSettings,
      requirementCount: 'one',
      requireSequentialProgress: true,
    })
    expect(formattedSettings.context_module.require_sequential_progress).toBe(false)
  })
})
