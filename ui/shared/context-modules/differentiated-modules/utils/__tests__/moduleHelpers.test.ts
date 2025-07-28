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

  it('parses the name', async () => {
    const element = getFixture('name')
    expect(await parseModule(element)).toEqual({
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

  it('parses unlockAt', async () => {
    const element = getFixture('unlockAt')
    expect(await parseModule(element)).toEqual({
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

  it('parses requirementCount', async () => {
    const element = getFixture('requirementCount')
    expect(await parseModule(element)).toEqual({
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

  it('parses requireSequentialProgress', async () => {
    const element = getFixture('requiresSequentialProgress')
    expect(await parseModule(element)).toEqual({
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

  it('parses publishFinalGrade', async () => {
    const element = getFixture('publishFinalGrade')
    expect(await parseModule(element)).toEqual({
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

  it('parses prerequisites', async () => {
    const element = getFixture('prerequisites')
    expect((await parseModule(element)).prerequisites).toEqual([
      {id: '14', name: 'Module A'},
      {id: '15', name: 'Module B'},
    ])
  })

  it('parses requirements', async () => {
    const element = getFixture('requirements')
    expect((await parseModule(element)).requirements).toEqual([
      {
        id: '93',
        name: 'HW 1',
        resource: 'assignment',
        type: 'mark',
        graded: true,
        minimumScore: '0',
        pointsPossible: '10',
      },
      {
        id: '94',
        name: 'Quiz 1',
        resource: 'quiz',
        type: 'score',
        graded: true,
        minimumScore: '70',
        pointsPossible: null,
      },
      {
        id: '95',
        name: 'Discussion 1',
        resource: 'discussion',
        type: 'score',
        graded: true,
        minimumScore: '5',
        pointsPossible: '10',
      },
      {
        id: '96',
        name: 'Discussion 2',
        resource: 'discussion',
        type: 'submit',
        graded: false,
        minimumScore: '0',
        pointsPossible: null,
      },
      {
        id: '97',
        name: 'Percentage item',
        resource: 'quiz',
        type: 'percentage',
        graded: true,
        minimumScore: '70',
        pointsPossible: '47',
      },
    ])
  })

  it('parses moduleItems', async () => {
    const element = getFixture('moduleItems')
    expect((await parseModule(element)).moduleItems).toEqual([
      {
        id: '93',
        name: 'HW 1',
        resource: 'assignment',
        graded: true,
        pointsPossible: '10',
      },
    ])
  })
})
