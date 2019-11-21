/*
 * Copyright (C) 2019 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.'
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

jest.mock('fs')
jest.mock('path')

const fs = require('fs')

const splitStrings = require('../split-strings')

jest.mock(
  'canvas-planner/locales/en.json',
  () => ({
    planner_string: 'Some string that planner needs'
  }),
  {virtual: true}
)

jest.mock(
  'canvas-rce/locales/en.json',
  () => ({
    rce_string: 'Some string that rce needs'
  }),
  {virtual: true}
)

jest.mock(
  '../../lib/en.json',
  () => ({
    planner_string: 'Some string that planner needs (EN)',
    rce_string: 'Some string that rce needs (EN)',
    other_string: 'something nothing cares about'
  }),
  {virtual: true}
)

jest.mock(
  '../../lib/fr.json',
  () => ({
    planner_string: 'Some string that planner needs (FR)',
    rce_string: 'Some string that rce needs (FR)'
  }),
  {virtual: true}
)

jest.mock(
  '../../lib/es.json',
  () => ({
    planner_string: 'Some string that planner needs (ES)',
    rce_string: 'Some string that rce needs (ES)'
  }),
  {virtual: true}
)

describe('splitStrings', () => {
  it('creates individual files containing only required strings for a given package', async () => {
    await splitStrings()
    expect(fs.promises.writeFile).toHaveBeenCalledTimes(6)
    expect(fs.promises.writeFile).toHaveBeenCalledWith(
      '/canvas/packages/translations/lib/canvas-planner/en.json',
      '{"planner_string":"Some string that planner needs (EN)"}'
    )
    expect(fs.promises.writeFile).toHaveBeenCalledWith(
      '/canvas/packages/translations/lib/canvas-planner/fr.json',
      '{"planner_string":"Some string that planner needs (FR)"}'
    )
    expect(fs.promises.writeFile).toHaveBeenCalledWith(
      '/canvas/packages/translations/lib/canvas-planner/es.json',
      '{"planner_string":"Some string that planner needs (ES)"}'
    )
    expect(fs.promises.writeFile).toHaveBeenCalledWith(
      '/canvas/packages/translations/lib/canvas-rce/en.json',
      '{"rce_string":"Some string that rce needs (EN)"}'
    )
    expect(fs.promises.writeFile).toHaveBeenCalledWith(
      '/canvas/packages/translations/lib/canvas-rce/fr.json',
      '{"rce_string":"Some string that rce needs (FR)"}'
    )
    expect(fs.promises.writeFile).toHaveBeenCalledWith(
      '/canvas/packages/translations/lib/canvas-rce/es.json',
      '{"rce_string":"Some string that rce needs (ES)"}'
    )
  })
})
