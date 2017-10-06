/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import * as mathml from 'mathml'

QUnit.module('MathML and MathJax test', {
  setup () {
    const mathElem = document.createElement('math')
    mathElem.innerHTML = '<mi>&#x3C0;</mi> <msup> <mi>r</mi> <mn>2</mn> </msup>'
    $('body')[0].appendChild(mathElem)
  }
})

test('loadMathJax loads mathJax', () => {
  window.MathJax = undefined
  sinon.stub($, 'getScript')
  mathml.loadMathJax('bogus')
  ok($.getScript.called)
  $.getScript.restore()
})

test('loadMathJax does not load mathJax', () => {
  sinon.stub($, 'getScript')
  window.MathJax = {}
  mathml.loadMathJax('bogus')
  ok(!$.getScript.called)
  $.getScript.restore()
})

test('isMathMLOnPage returns true', () => {
  ok(mathml.isMathMLOnPage())
})

test('isMathJaxLoaded return true', () => {
  window.MathJax = {}
  ok(mathml.isMathJaxLoaded())
})

test('reloadElement reloads the element', () => {
  window.MathJax = {
    Hub: {
      Queue: () => {}
    }
  }
  sinon.stub(window.MathJax.Hub, 'Queue')
  mathml.reloadElement('content')
  ok(window.MathJax.Hub.Queue.called)
})
