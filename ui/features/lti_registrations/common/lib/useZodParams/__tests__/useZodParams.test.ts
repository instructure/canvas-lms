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

import {parseUrlParams} from '../useZodParams'
import * as z from 'zod'

describe('parseUrlParams', () => {
  it('should parse params correctly', () => {
    const result = parseUrlParams(
      {
        a: z.string(),
        b: z.enum(['foo', 'bar']),
      },
      {
        a: 'baz',
        b: 'bar',
      }
    )

    if (result.success) {
      expect(result.value.a).toEqual('baz')
      expect(result.value.b).toEqual('bar')
    } else {
      throw new Error('Expected successful parsing')
    }
  })

  it('should fail when required params are not included', () => {
    const result = parseUrlParams(
      {
        a: z.string(),
        b: z.enum(['foo', 'bar']),
      },
      {
        a: 'baz',
      }
    )

    expect(result.success).toEqual(false)
  })
})
