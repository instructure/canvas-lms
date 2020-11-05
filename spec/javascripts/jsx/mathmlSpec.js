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
import mathml from 'mathml'

let stub = null
QUnit.module('MathML and MathJax test', {
  beforeEach: () => {
    const mathElem = document.createElement('math')
    mathElem.innerHTML = '<mi>&#x3C0;</mi> <msup> <mi>r</mi> <mn>2</mn> </msup>'
    document.getElementById('fixtures').innerHTML = mathElem.outerHTML
    window.ENV.locale = 'en'
  },
  afterEach: () => {
    stub && stub.restore()
    stub = null
    delete window.MathJax
    delete window.MathJaxIsLoading
  },
  after: () => {
    document.getElementById('fixtures').innerHTML = ''
  }
})

test('loadMathJax loads mathJax', () => {
  stub = sinon.stub($, 'ajax')
  mathml.loadMathJax('bogus')
  ok($.ajax.calledOnce)
})

test('loadMathJax does not load mathJax', () => {
  stub = sinon.stub($, 'ajax')
  window.MathJax = {
    Hub: {
      Queue: () => {}
    }
  }
  mathml.loadMathJax('bogus')
  ok(!$.ajax.called)
})

test("loadMathJax doesn't download mathjax if in-flight", () => {
  stub = sinon.stub($, 'ajax')
  mathml.loadMathJax('bogus')
  mathml.loadMathJax('bogus')
  sinon.assert.calledOnce($.ajax)
})

test('isMathJaxLoaded return true', () => {
  window.MathJax = {Hub: {}}
  ok(mathml.isMathJaxLoaded())
})

test('reloadElement reloads the element', () => {
  window.MathJax = {
    Hub: {
      Queue: () => {}
    }
  }
  stub = sinon.stub(window.MathJax.Hub, 'Queue')
  mathml.reloadElement('content')
  ok(window.MathJax.Hub.Queue.called)
})

QUnit.module('isMathOnPage', {
  setup() {
    window.ENV = {
      FEATURES: {}
    }
  }
})

test('returns true if there is mathml', () => {
  const mathElem = document.createElement('math')
  mathElem.innerHTML = '<mi>&#x3C0;</mi> <msup> <mi>r</mi> <mn>2</mn> </msup>'
  document.getElementById('fixtures').innerHTML = mathElem.outerHTML
  equal(mathml.isMathOnPage(), true)
})

test('returns false if there is a .math_equation_latex element', () => {
  const mathElem = document.createElement('span')
  mathElem.setAttribute('class', 'math_equation_latex')
  mathElem.innerHTML = '2 + 2'
  document.getElementById('fixtures').innerHTML = mathElem.outerHTML
  equal(mathml.isMathOnPage(), false)
})

QUnit.module('isMathOnPage, with new_math_equation_handling on', {
  setup() {
    window.ENV = {
      FEATURES: {
        new_math_equation_handling: true
      }
    }
  }
})

test('returns true if there is mathml', () => {
  const mathElem = document.createElement('math')
  mathElem.innerHTML = '<mi>&#x3C0;</mi> <msup> <mi>r</mi> <mn>2</mn> </msup>'
  document.getElementById('fixtures').innerHTML = mathElem.outerHTML
  equal(mathml.isMathOnPage(), true)
})

test('returns true if there is a .math_equation_latex element', () => {
  const mathElem = document.createElement('span')
  mathElem.setAttribute('class', 'math_equation_latex')
  mathElem.innerHTML = '2 + 2'
  document.getElementById('fixtures').innerHTML = mathElem.outerHTML
  equal(mathml.isMathOnPage(), true)
})

test('returns false if there is block-delmited math', () => {
  const mathElem = document.createElement('span')
  mathElem.innerHTML = '$$y = mx + b$$'
  document.getElementById('fixtures').innerHTML = mathElem.outerHTML
  equal(mathml.isMathOnPage(), false)
})

test('returns true if there is inline-delmited math', () => {
  const mathElem = document.createElement('span')
  mathElem.innerHTML = '\\(ax^2 + by + c = 0\\)'
  document.getElementById('fixtures').innerHTML = mathElem.outerHTML
  equal(mathml.isMathOnPage(), false)
})

QUnit.module('isMathOnPage, including inline LaTex', {
  setup() {
    window.ENV = {
      FEATURES: {
        new_math_equation_handling: true,
        inline_math_everywhere: true
      }
    }
  }
})

test('returns true if there is mathml', () => {
  const mathElem = document.createElement('math')
  mathElem.innerHTML = '<mi>&#x3C0;</mi> <msup> <mi>r</mi> <mn>2</mn> </msup>'
  document.getElementById('fixtures').innerHTML = mathElem.outerHTML
  equal(mathml.isMathOnPage(), true)
})

test('returns true if there is a .math_equation_latex element', () => {
  const mathElem = document.createElement('span')
  mathElem.setAttribute('class', 'math_equation_latex')
  mathElem.innerHTML = '2 + 2'
  document.getElementById('fixtures').innerHTML = mathElem.outerHTML
  equal(mathml.isMathOnPage(), true)
})

test('returns true if there is block-delmited math', () => {
  const mathElem = document.createElement('span')
  mathElem.innerHTML = '$$y = mx + b$$'
  document.getElementById('fixtures').innerHTML = mathElem.outerHTML
  equal(mathml.isMathOnPage(), true)
})

test('returns true if there is inline-delmited math', () => {
  const mathElem = document.createElement('span')
  mathElem.innerHTML = '\\(ax^2 + by + c = 0\\)'
  document.getElementById('fixtures').innerHTML = mathElem.outerHTML
  equal(mathml.isMathOnPage(), true)
})

QUnit.module('handles "process-new-math" events', {})

test('debounces event handler', assert => {
  const done = assert.async()
  const spy = sinon.spy(mathml, 'processNewMathOnPage')
  window.dispatchEvent(new Event('process-new-math'))
  window.dispatchEvent(new Event('process-new-math'))
  equal(spy.callCount, 0)
  window.setTimeout(() => {
    equal(spy.callCount, 1)
    done()
  }, 501)
})
