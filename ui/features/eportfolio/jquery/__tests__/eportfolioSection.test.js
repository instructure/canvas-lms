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

import {fetchContent} from '../eportfolio_section'
import fixtures from '@canvas/test-utils/fixtures'

let $section = null

describe('EportfolioSection -> fetchContent', () => {
  beforeEach(() => {
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
  })

  afterEach(() => {
    fixtures.teardown()
  })

  it('grabs section content for rich_text type', () => {
    const content = fetchContent($section, 'rich_text', 'section1')
    expect(content['section1[section_type]']).toEqual('rich_text')
    expect(content['section1[content]'].trim()).toEqual('<p>Some Editor Content</p>')
  })

  it('uses edit field value for html type', () => {
    const content = fetchContent($section, 'html', 'section1')
    expect(content['section1[section_type]']).toEqual('html')
    expect(content['section1[content]'].trim()).toEqual('Some HTML Content')
  })
})
