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

import $ from 'jquery'
import {adjustFooter} from '../../index'

describe('adjustFooter', () => {
  beforeEach(() => {
    document.body.innerHTML = `<div class="discussion-redesign-layout"></div>
      <div id="content"></div>
      <div id="module_sequence_footer_container" style="padding-right: 20px; width: 100px;">Container</div>
      <div id="module_sequence_footer" style="width:20px; right: 5px; bottom: 0; "></div>`
  })

  afterEach(() => {
    document.body.innerHTML = ''
  })

  it('should adjust the width and right position of the footer', () => {
    adjustFooter()
    setTimeout(() => {
      const footer = $('#module_sequence_footer')
      expect(footer.css('width')).toBe('calc(100px - 20px)')
      expect(footer.css('right')).toBe('20px')
    })
  })

  it('should not adjust the footer if the container does not exist', () => {
    $('#module_sequence_footer_container').remove()
    adjustFooter()
    setTimeout(() => {
      const footer = $('#module_sequence_footer')
      expect(footer.css('width')).toBe('20px')
      expect(footer.css('right')).toBe('5px')
    })
  })
})
