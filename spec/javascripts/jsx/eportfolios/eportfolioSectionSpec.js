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

import {fetchContent} from 'ui/features/eportfolio/jquery/eportfolio_section'
import fixtures from 'helpers/fixtures'

let $section = null

QUnit.module('EportfolioSection -> fetchContent', {
  setup() {
    fixtures.setup()
    $section = fixtures.create(
      "<div id='eportfolio_section'>" +
        "  <div class='section_content'>" +
        '    <p>Some Editor Content</p>' +
        '  </div>' +
        "  <textarea class='edit_section'>" +
        '    Some HTML Content' +
        '  </textarea>' +
        '</div>'
    )
  },

  teardown() {
    fixtures.teardown()
  },
})

test('grabs section content for rich_text type', () => {
  const content = fetchContent($section, 'rich_text', 'section1')
  equal(content['section1[section_type]'], 'rich_text')
  equal(content['section1[content]'].trim(), '<p>Some Editor Content</p>')
})

test('uses edit field value for html type', () => {
  const content = fetchContent($section, 'html', 'section1')
  equal(content['section1[section_type]'], 'html')
  equal(content['section1[content]'].trim(), 'Some HTML Content')
})
