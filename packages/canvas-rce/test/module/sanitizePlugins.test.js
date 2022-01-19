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

import assert from 'assert'
import {sanitizePlugins} from '../../src/rce/sanitizePlugins'

describe('sanitizePlugins', () => {
  it('preserves plugin object structure', () => {
    const rawOptions = {
      plugins: ['link', 'table'],
      toolbar: [
        'bold,italic,underline,indent,superscript,subscript,bullist,numlist',
        'table,link,unlink,instructure_image,ltr,rtl'
      ]
    }
    const cleanOptions = sanitizePlugins(rawOptions)

    assert.deepEqual(cleanOptions, rawOptions)
  })

  it('converts string to array removing spaces', () => {
    const rawOptions = 'bold,italic,underline,indent, superscript, subscript'
    const cleanOptions = sanitizePlugins(rawOptions)

    assert.deepEqual(cleanOptions, [
      'bold',
      'italic',
      'underline',
      'indent',
      'superscript',
      'subscript'
    ])
  })
})
