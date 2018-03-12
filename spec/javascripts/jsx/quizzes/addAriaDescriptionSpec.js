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

import addAriaDescription from 'quiz_labels'
import fixtures from 'helpers/fixtures'

var $elem = null

QUnit.module("Add aria descriptions", {
  setup() {
    $elem = $(
      '<div>' +
        '<input type="text" />' +
        '<div class="deleteAnswerId"></div>' +
        '<div class="editAnswerId"></div>' +
        '<div class="commentAnswerId"></div>' +
        '<div class="selectAsCorrectAnswerId"></div>' +
      '</div>'
    )

    $('#fixtures').html($elem[0])
  },

  teardown() {
    $('#fixtures').empty()
  }
});

test('add aria descriptions to quiz answer options', () => {
  addAriaDescription($elem, '1')
  equal($elem.find('input:text').attr('aria-describedby'), 'answer1')
  equal($elem.find('.deleteAnswerId').text(), 'Answer 1')
  equal($elem.find('.editAnswerId').text(), 'Answer 1')
  equal($elem.find('.commentAnswerId').text(), 'Answer 1')
  equal($elem.find('.selectAsCorrectAnswerId').text(), 'Answer 1')
})
