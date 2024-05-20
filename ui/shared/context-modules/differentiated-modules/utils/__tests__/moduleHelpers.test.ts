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

import {parseModule} from '../moduleHelpers'
import {getFixture} from './fixtures'
import moment from 'moment'

describe('parseModule', () => {
  beforeAll(() => {
    window.ENV.TIMEZONE = 'America/Denver'
    moment.tz.setDefault('America/Denver')
  })

  it('parses the name', () => {
    const element = getFixture('name')
    expect(parseModule(element)).toEqual({
      moduleId: '8',
      moduleName: 'Module 1',
      unlockAt: undefined,
      requirementCount: 'all',
      requireSequentialProgress: false,
      publishFinalGrade: false,
      prerequisites: [],
      moduleList: [],
      requirements: [],
      moduleItems: [],
    })
  })

  it('parses unlockAt', () => {
    const element = getFixture('unlockAt')
    expect(parseModule(element)).toEqual({
      moduleId: '8',
      moduleName: '',
      unlockAt: '2023-08-02T06:00:00.000Z',
      requirementCount: 'all',
      requireSequentialProgress: false,
      publishFinalGrade: false,
      prerequisites: [],
      moduleList: [],
      requirements: [],
      moduleItems: [],
    })
  })

  it('parses requirementCount', () => {
    const element = getFixture('requirementCount')
    expect(parseModule(element)).toEqual({
      moduleId: '8',
      moduleName: '',
      unlockAt: undefined,
      requirementCount: 'one',
      requireSequentialProgress: false,
      publishFinalGrade: false,
      prerequisites: [],
      moduleList: [],
      requirements: [],
      moduleItems: [],
    })
  })

  it('parses requireSequentialProgress', () => {
    const element = getFixture('requiresSequentialProgress')
    expect(parseModule(element)).toEqual({
      moduleId: '8',
      moduleName: '',
      unlockAt: undefined,
      requirementCount: 'all',
      requireSequentialProgress: true,
      publishFinalGrade: false,
      prerequisites: [],
      moduleList: [],
      requirements: [],
      moduleItems: [],
    })
  })

  it('parses publishFinalGrade', () => {
    const element = getFixture('publishFinalGrade')
    expect(parseModule(element)).toEqual({
      moduleId: '8',
      moduleName: '',
      unlockAt: undefined,
      requirementCount: 'all',
      requireSequentialProgress: false,
      publishFinalGrade: true,
      prerequisites: [],
      moduleList: [],
      requirements: [],
      moduleItems: [],
    })
  })

  it('parses prerequisites', () => {
    const element = getFixture('prerequisites')
    expect(parseModule(element).prerequisites).toEqual([
      {id: '14', name: 'Module A'},
      {id: '15', name: 'Module B'},
    ])
  })

  it('parses requirements', () => {
    const element = getFixture('requirements')
    expect(parseModule(element).requirements).toEqual([
      {
        id: '93',
        name: 'HW 1',
        resource: 'assignment',
        type: 'mark',
        minimumScore: '0',
        pointsPossible: '10',
      },
      {
        id: '94',
        name: 'Quiz 1',
        resource: 'quiz',
        type: 'score',
        minimumScore: '70',
        pointsPossible: null,
      },
    ])
  })
})
