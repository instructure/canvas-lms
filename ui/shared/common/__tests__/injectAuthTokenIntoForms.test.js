/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {isCrossSite} from '../injectAuthTokenIntoForms'

describe('isCrossSite', () => {
  // eslint-disable-next-line no-restricted-globals
  const currentHostname = location.hostname

  it('works for absolute urls', () => {
    expect(isCrossSite(`https://${currentHostname}/whatevs`)).toEqual(false)
    expect(isCrossSite('https://elsewhere.net/whatevs')).toEqual(true)
    expect(isCrossSite(`//${currentHostname}/whatevs`)).toEqual(false)
    expect(isCrossSite('//elsewhere.net/whatevs')).toEqual(true)
  })

  it('works for relative urls', () => {
    expect(isCrossSite('/somewhere.net/whatevs')).toEqual(false)
    expect(isCrossSite('/')).toEqual(false)
  })

  it('is cool with empty values', () => {
    expect(isCrossSite('')).toEqual(false)
    expect(isCrossSite(null)).toEqual(false)
    expect(isCrossSite(undefined)).toEqual(false)
  })
})
