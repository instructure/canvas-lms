/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import tinymce from 'compiled/editor/stocktiny'
import ValidatedMixin from 'compiled/views/ValidatedMixin'

let textarea = null

QUnit.module('ValidatedMixin', {
  setup() {
    tinymce.remove()
    textarea = $("<textarea id='a42' name='message' data-rich_text='true'></textarea>")
    $('#fixtures').append(textarea)
    ValidatedMixin.$ = $
  },
  teardown() {
    textarea.remove()
    $('#fixtures').empty()
  }
})

test('it can find tinymce instances as fields', (assert) => {

  const done = assert.async()
  tinymce.init({
    selector: '#fixtures textarea#a42',
    }).then(() => {
      const element = ValidatedMixin.findField('message')
      equal(element.length, 1)
      done()
    })

})
