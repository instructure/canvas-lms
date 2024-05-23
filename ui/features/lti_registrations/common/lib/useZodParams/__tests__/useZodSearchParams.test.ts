/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import * as z from 'zod'
import type {ParamsParseResult} from '../ParamsParseResult'
import {
  parseSearchParams,
  type ParsedSearchParamsValue,
  type SearchParameterSchemaMap,
} from '../useZodSearchParams'

const expectSuccess = <Params extends SearchParameterSchemaMap>(
  url: string,
  params: Params,
  cb: (
    r: Extract<ParamsParseResult<ParsedSearchParamsValue<Params>>, {success: true}>['value']
  ) => void
) => {
  const searchParams = new URLSearchParams(url)

  const result = parseSearchParams(params, searchParams)

  if (result.success) {
    cb(result.value)
  } else {
    throw new Error('Expected successful parsing')
  }
}

describe('parseSearchParams', () => {
  it('should parse URLSearchParams', () => {
    expectSuccess(
      'a=foo&a=bar&b=yes',
      {
        a: z.array(z.string()),
        b: z.string(),
        c: z.string().default('param'),
        d: z.string().optional(),
      },
      value => {
        expect(value).toEqual({
          a: ['foo', 'bar'],
          b: 'yes',
          c: 'param',
          d: undefined,
        })
      }
    )
  })

  it('should take the first parameter if multiple provided', () => {
    expectSuccess(
      'a=foo&a=bar',
      {
        a: z.string(),
      },
      value => {
        expect(value).toEqual({
          a: 'foo',
        })
      }
    )
  })

  it('should return an empty array if schema is an array', () => {
    expectSuccess(
      '',
      {
        a: z.array(z.string()),
      },
      value => {
        expect(value).toEqual({
          a: [],
        })
      }
    )
  })

  it('should return errors', () => {
    const searchParams = new URLSearchParams('')
    const result = parseSearchParams(
      {
        a: z.string(),
      },
      searchParams
    )
    expect(result.success).toBe(false)
  })
})
