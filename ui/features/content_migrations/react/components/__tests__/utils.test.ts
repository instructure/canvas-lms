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

import {humanReadableSize} from '../utils'

describe('humanReadableSize', () => {
  it('returns Bytes', () => {
    expect(humanReadableSize(10)).toBe('10.0 Bytes')
  })

  it('returns KB', () => {
    expect(humanReadableSize(2.5 * 1024)).toBe('2.5 KB')
  })

  it('returns MB', () => {
    expect(humanReadableSize(2.5 * 1024 ** 2)).toBe('2.5 MB')
  })

  it('returns GB', () => {
    expect(humanReadableSize(3.6 * 1024 ** 3)).toBe('3.6 GB')
  })

  it('returns TB', () => {
    expect(humanReadableSize(5.5 * 1024 ** 4)).toBe('5.5 TB')
  })

  it('returns PB', () => {
    expect(humanReadableSize(7.1 * 1024 ** 5)).toBe('7.1 PB')
  })

  it('returns EB', () => {
    expect(humanReadableSize(6.2 * 1024 ** 6)).toBe('6.2 EB')
  })

  it('returns ZB', () => {
    expect(humanReadableSize(4.9 * 1024 ** 7)).toBe('4.9 ZB')
  })

  it('returns YB', () => {
    expect(humanReadableSize(1.1 * 1024 ** 8)).toBe('1.1 YB')
  })
})
