/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {initializeContent, convertApiUserContent} from '../contentUtils'

describe('contentUtils::convertApiUserContent', () => {
  const oldEnv = process.env
  const double = x => 2 * x

  beforeEach(() => {
    jest.resetModules()
    process.env = {...oldEnv}
    delete process.env.NODE_ENV
    initializeContent({convertApiUserContent: double})
  })

  afterEach(() => {
    process.env = oldEnv
  })

  it('returns transformed content normally', () => {
    const value = 50

    expect(convertApiUserContent(value)).toBe(double(value))
  })

  it('returns untransformed content in test', () => {
    const value = 75
    process.env.NODE_ENV = 'test'

    expect(convertApiUserContent(value)).toBe(value)
  })
})
