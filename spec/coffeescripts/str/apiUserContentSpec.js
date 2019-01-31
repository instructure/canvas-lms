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

import apiUserContent from 'compiled/str/apiUserContent'

let mathml_html

QUnit.module('apiUserContent.convert', {
  setup() {
    mathml_html ="<div><ul>\n" +
      "<li><img class=\"equation_image\" data-mathml=\"&lt;math xmlns=&quot;http://www.w3.org/1998/Math/MathML&quot; display=&quot;inline&quot;&gt;&lt;mi&gt;i&lt;/mi&gt;&lt;mi&gt;n&lt;/mi&gt;&lt;mi&gt;t&lt;/mi&gt;&lt;mi&gt;f&lt;/mi&gt;&lt;mo stretchy='false'&gt;(&lt;/mo&gt;&lt;mi&gt;x&lt;/mi&gt;&lt;mo stretchy='false'&gt;)&lt;/mo&gt;&lt;mo&gt;/&lt;/mo&gt;&lt;mi&gt;g&lt;/mi&gt;&lt;mo stretchy='false'&gt;(&lt;/mo&gt;&lt;mi&gt;x&lt;/mi&gt;&lt;mo stretchy='false'&gt;)&lt;/mo&gt;&lt;/math&gt;\"></li>\n" +
      "<li><img class=\"equation_image\" data-mathml='&lt;math xmlns=\"http://www.w3.org/1998/Math/MathML\" display=\"inline\"&gt;&lt;mo lspace=\"thinmathspace\" rspace=\"thinmathspace\"&gt;&amp;Sum;&lt;/mo&gt;&lt;mn&gt;1&lt;/mn&gt;&lt;mo&gt;.&lt;/mo&gt;&lt;mo&gt;.&lt;/mo&gt;&lt;mi&gt;n&lt;/mi&gt;&lt;/math&gt;'></li>\n" +
      "<li><img class=\"nothing_special\"></li>\n"+
    "</ul></div>"
  }
})

test('moves mathml into a screenreader element', () => {
  const output = apiUserContent.convert(mathml_html)
  ok(output.includes('<span class="hidden-readable"><math '))
})

test('prevents XSS on data-mathml content', () => {
  const xss_mathml = "<img class='equation_image' data-mathml='<img src=x onerror=prompt(document.cookie); />'>"
  const output = apiUserContent.convert(xss_mathml)
  ok(!output.includes('onerror'))
})

test('mathml need not be screenreadered if editing content (this would start an update loop)', () => {
  const output = apiUserContent.convert(mathml_html, {forEditing: true})
  ok(!output.includes('<span class="hidden-readable"><math '))
})

test('adds media comments for tagged audio content', () => {
  const html =
    "<div><audio class='instructure_inline_media_comment' data-media_comment_id='42' data-media_comment_type='audio' data-alt='audio file'><span>24</span></audio></div>"
  const output = apiUserContent.convert(html)
  const expected =
    '<div><a id="media_comment_42" data-media_comment_type="audio" class="instructure_inline_media_comment audio_comment" data-alt="audio file"><span>24</span></a></div>'
  equal(output, expected)
})

test('removes embed tag from within object tag', () => {
  const object_html = '<div><object class="instructure_user_content"><embed></embed></object></div>'
  const expected = '<div><object class="instructure_user_content"></object></div>'
  const output = apiUserContent.convert(object_html, {forEditing: true})
  equal(output, expected)
})

test('does not remove embed tag from within object#kaltura_player tag', () => {
  const object_html =
    '<div><object class="instructure_user_content" id="kaltura_player"><embed></object></div>'
  const output = apiUserContent.convert(object_html, {forEditing: true})
  equal(output, object_html)
})
