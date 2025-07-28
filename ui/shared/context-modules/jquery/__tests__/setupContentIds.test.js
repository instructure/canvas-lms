/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import $ from 'jquery'
import setupContentIds from '../setupContentIds'

describe('Modules Utilities: setupContentIds', () => {
  test('It puts the proper attribute values in place when called', () => {
    const fakeModuleHtml = `
      <div>
        <div class="header">
          <span id="place1" aria-controls="context_module_content_"></span>
          <span id="place2" aria-controls="context_module_content_"></span>
        </div>
        <div class="content" id="context_module_content_"></div>
      </div>
    `

    const $fakeModule = $(fakeModuleHtml)
    setupContentIds($fakeModule, 42)

    expect($fakeModule.find('#context_module_content_42')).toHaveLength(1)
    expect($fakeModule.find('#place1').attr('aria-controls')).toBe('context_module_content_42')
    expect($fakeModule.find('#place2').attr('aria-controls')).toBe('context_module_content_42')
  })
})
