/*
 * Copyright (C) 2013 - present Instructure, Inc.
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
import 'compiled/jquery/serializeForm'

const $sampleForm = $(`
  <form>
    Radio
    <input type="radio" value="group_val_1" name="radio_group" checked />
    <input type="radio" value="group_val_2" name="radio_group" />

    Checked checkbox
    <input type="checkbox" value="checkbox1" name="checkbox[1]" checked />

    Unchecked checkbox
    <input type="checkbox" value="checkbox2" name="checkbox[2]" />

    Unchecked checkbox with hidden field (a la rails and handlebars helper)
    <input type="hidden" value="0" name="checkbox[3]" />
    <input type="checkbox" value="1" name="checkbox[3]" />

    Text field
    <input type="text" value="asdf" name="text" />

    Disabled field
    <input type="text" value="qwerty" name="text2" disabled />

    Textarea
    <textarea name="textarea">hello\nworld</textarea>

    Select
    <select name="select"><option>1</option><option selected>2</option></select>

    Multi-select
    <select name="multiselect" multiple>
      <option>1</option>
      <option selected>2</option>
      <option selected>3</option>
    </select>
  </form>
`)

QUnit.module('SerializeForm')

test('Serializes valid input items correctly', () => {
  const serialized = $sampleForm.serializeForm()
  deepEqual(serialized, [
    {name: 'radio_group', value: 'group_val_1'},
    {name: 'checkbox[1]', value: 'checkbox1'},
    {name: 'checkbox[3]', value: '0'},
    {name: 'text', value: 'asdf'},
    {name: 'textarea', value: 'hello\r\nworld'},
    {name: 'select', value: '2'},
    {name: 'multiselect', value: '2'},
    {name: 'multiselect', value: '3'}
  ])
})
