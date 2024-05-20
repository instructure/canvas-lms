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
import 'jquery-migrate'
import ValidatedMixin from '@canvas/forms/backbone/views/ValidatedMixin'
import RichContentEditor from '@canvas/rce/RichContentEditor'

let textarea = null

QUnit.module('ValidatedMixin', {
  setup() {
    textarea = $("<textarea id='a42' name='message' data-rich_text='true'></textarea>")
    $('#fixtures').append(textarea)
    ValidatedMixin.$ = $
  },
  teardown() {
    textarea.remove()
    $('#fixtures').empty()
  },
})

test('it can find tinymce instances as fields', assert => {
  const done = assert.async()

  RichContentEditor.loadNewEditor($('#a42'), {}, () => {
    // eslint-disable-next-line promise/catch-or-return
    tinymce
      .init({
        selector: '#fixtures textarea#a42',
      })
      .then(() => {
        const element = ValidatedMixin.findField('message')
        equal(element.length, 1)
        // eslint-disable-next-line promise/no-callback-in-promise
        done()
      })
  })
})
