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

import {mergeTemplates} from '../mergeTemplates'

describe('mergeTemplates', () => {
  it('should merge global templates into api templates', () => {
    const apiTemplates = [
      {id: '1', global_id: 'a', name: 'AA Api 1'},
      {id: '2', global_id: 'b', name: 'CC Api 2'},
      {id: '3', global_id: 'c', name: 'DD Api 3'},
    ]
    const globalTemplates = [
      {id: '2', global_id: 'a', name: 'AA global 1'},
      {id: '4', global_id: 'z', name: 'BB global 4'},
      {id: '5', global_id: 'x', name: 'Blank'},
    ]
    // @ts-expect-error
    const mergedTemplates = mergeTemplates(apiTemplates, globalTemplates)
    // blank is sorted to the top
    expect(mergedTemplates[0].name).toEqual('Blank')

    expect(mergedTemplates).toEqual([
      {id: '5', global_id: 'x', name: 'Blank'},
      {id: '1', global_id: 'a', name: 'AA Api 1'},
      {id: '2', global_id: 'a', name: 'AA global 1'},
      {id: '4', global_id: 'z', name: 'BB global 4'},
      {id: '3', global_id: 'c', name: 'DD Api 3'},
    ])
  })

  it('can handle rejected promise results', () => {
    const apiTemplates = [
      {id: '1', global_id: 'a', name: 'Api 1'},
      {id: '2', global_id: 'b', name: 'Api 2'},
      {id: '3', global_id: 'c', name: 'Api 3'},
    ]
    const globalTemplates = undefined
    // @ts-expect-error
    const mergedTemplates = mergeTemplates(apiTemplates, globalTemplates)
    expect(mergedTemplates).toEqual([
      {id: '1', global_id: 'a', name: 'Api 1'},
      {id: '2', global_id: 'b', name: 'Api 2'},
      {id: '3', global_id: 'c', name: 'Api 3'},
    ])

    // @ts-expect-error
    const mergedTemplates2 = mergeTemplates(undefined, apiTemplates)
    expect(mergedTemplates2).toEqual([
      {id: '1', global_id: 'a', name: 'Api 1'},
      {id: '2', global_id: 'b', name: 'Api 2'},
      {id: '3', global_id: 'c', name: 'Api 3'},
    ])
  })
})
