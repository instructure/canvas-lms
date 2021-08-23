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

import {splitTextIntoLines, convertFileToBase64} from '../utils'

describe('splitTextIntoLines()', () => {
  it('returns empty list if text is empty', () => {
    expect(splitTextIntoLines('', 10)).toStrictEqual([])
  })

  it('returns empty list if text is has just spaces', () => {
    expect(splitTextIntoLines('   ', 10)).toStrictEqual([])
  })

  it('returns empty list if max limit is lower than 1', () => {
    expect(splitTextIntoLines('hello', 0)).toStrictEqual([])
  })

  it('returns a one-item list when a text that is lower than the limit', () => {
    expect(splitTextIntoLines('Hello world!', 20)).toStrictEqual(['Hello world!'])
  })

  it('returns a lines list when a text that exceeds limit', () => {
    const text =
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed eiusmod tempor incidunt ut labore et dolore magna aliqua.'
    expect(splitTextIntoLines(text, 20)).toStrictEqual([
      'Lorem ipsum dolor sit',
      'amet, consectetur adipiscing',
      'elit, sed eiusmod tempor',
      'incidunt ut labore et',
      'dolore magna aliqua.'
    ])
  })

  it('returns a lines list when a text contains a long word that exceeds limit', () => {
    expect(splitTextIntoLines('Incomprehensibility is a long word!', 10)).toStrictEqual([
      'Incompreh-',
      'ensibility',
      'is a long',
      'word!'
    ])
  })
})

describe('convertFileToBase64()', () => {
  it('executes readAsDataURL with correct arguments', async () => {
    const blob = new Blob()
    const readAsDataURLSpy = jest.spyOn(FileReader.prototype, 'readAsDataURL')
    expect(await convertFileToBase64(blob)).toEqual('data:;base64,')
    expect(readAsDataURLSpy).toHaveBeenCalledWith(blob)
  })
})
