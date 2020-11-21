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
import mathml, {mathImageHelper} from 'mathml'

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

QUnit.module('isMathInElement', {
  beforeEach: () => {
    window.ENV = {
      FEATURES: {}
    }
  }
})

test('returns true if there is mathml', () => {
  const mathElem = document.createElement('div')
  mathElem.innerHTML = '<math><mi>&#x3C0;</mi> <msup> <mi>r</mi> <mn>2</mn> </msup></math>'
  document.getElementById('fixtures').innerHTML = mathElem.outerHTML
  equal(mathml.isMathInElement(mathElem), true)
})

test('returns false if there is a .math_equation_latex element', () => {
  const mathElem = document.createElement('span')
  mathElem.innerHTML = '<span class="math_equation_latex">2 + 2</span>'

  document.getElementById('fixtures').innerHTML = mathElem.outerHTML
  equal(mathml.isMathInElement(mathElem), false)
})

QUnit.module('isMathInElement, with new_math_equation_handling on', {
  beforeEach: () => {
    window.ENV = {
      FEATURES: {
        new_math_equation_handling: true
      }
    }
  }
})

test('returns true if there is mathml', () => {
  const mathElem = document.createElement('span')
  mathElem.innerHTML = '<math><mi>&#x3C0;</mi> <msup> <mi>r</mi> <mn>2</mn> </msup>></math>'
  document.getElementById('fixtures').innerHTML = mathElem.outerHTML
  equal(mathml.isMathInElement(mathElem), true)
})

test('returns true if there is a .math_equation_latex element', () => {
  const mathElem = document.createElement('span')
  mathElem.innerHTML = '<span class="math_equation_latex">2 + 2</span>'

  document.getElementById('fixtures').innerHTML = mathElem.outerHTML
  equal(mathml.isMathInElement(mathElem), true)
})

test('returns false if there is block-delmited math', () => {
  const mathElem = document.createElement('span')
  mathElem.innerHTML = '$$y = mx + b$$'
  document.getElementById('fixtures').innerHTML = mathElem.outerHTML
  equal(mathml.isMathInElement(mathElem), false)
})

test('returns true if there is inline-delmited math', () => {
  const mathElem = document.createElement('span')
  mathElem.innerHTML = '\\(ax^2 + by + c = 0\\)'
  document.getElementById('fixtures').innerHTML = mathElem.outerHTML
  equal(mathml.isMathInElement(mathElem), false)
})

QUnit.module('isMathInElement, including inline LaTex', {
  beforeEach: () => {
    window.ENV = {
      FEATURES: {
        new_math_equation_handling: true,
        inline_math_everywhere: true
      }
    }
  }
})

test('returns true if there is mathml', () => {
  const mathElem = document.createElement('span')
  mathElem.innerHTML = '<math><mi>&#x3C0;</mi> <msup> <mi>r</mi> <mn>2</mn> </msup></math>'
  document.getElementById('fixtures').innerHTML = mathElem.outerHTML
  equal(mathml.isMathInElement(mathElem), true)
})

test('returns true if there is a .math_equation_latex element', () => {
  const mathElem = document.createElement('span')
  mathElem.innerHTML = '<span class="math_equation_latex">2 + 2</span>'

  document.getElementById('fixtures').innerHTML = mathElem.outerHTML
  equal(mathml.isMathInElement(mathElem), true)
})

test('returns true if there is block-delmited math', () => {
  const mathElem = document.createElement('span')
  mathElem.innerHTML = '$$y = mx + b$$'
  document.getElementById('fixtures').innerHTML = mathElem.outerHTML
  equal(mathml.isMathInElement(mathElem), true)
})

test('returns true if there is inline-delmited math', () => {
  const mathElem = document.createElement('span')
  mathElem.innerHTML = '\\(ax^2 + by + c = 0\\)'
  document.getElementById('fixtures').innerHTML = mathElem.outerHTML
  equal(mathml.isMathInElement(mathElem), true)
})
test('handles "process-new-math" event', () => {
  const spy = sinon.spy(mathml, 'processNewMathInElem')
  const elem = document.createElement('span')
  window.dispatchEvent(new CustomEvent('process-new-math', {detail: {target: elem}}))
  ok(spy.calledWith(elem))
})

QUnit.module('mathEquationHelper', {
  beforeEach: () => {
    window.ENV = {
      FEATURES: {
        new_math_equation_handling: true,
        inline_math_everywhere: true
      }
    }
    document.getElementById('fixtures').innerHTML = ''
  },
  afterEach: () => {
    document.getElementById('fixtures').innerHTML = ''
  }
})

test('getImageEquationText uses data-equation-content if available', () => {
  const img = document.createElement('img')
  img.setAttribute('data-equation-content', 'y = sqrt{x}')
  equal(mathImageHelper.getImageEquationText(img), 'y = sqrt{x}')
})

test('getImageEquationText uses img src if missing data-equation-content', () => {
  const img = document.createElement('img')
  const txt = encodeURIComponent(encodeURIComponent('y = sqrt{x}'))
  img.setAttribute('src', `http://host/equation_images/${txt}`)
  equal(mathImageHelper.getImageEquationText(img), 'y = sqrt{x}')
})

test('getImageEquationText returns undefined if it not an equation image', () => {
  const img = document.createElement('img')
  const txt = encodeURIComponent(encodeURIComponent('y = sqrt{x}'))
  img.setAttribute('src', `http://host/not_equation_images/${txt}`)
  equal(mathImageHelper.getImageEquationText(img), undefined)
})

test('catchEquationImages only processes loaded images', assert => {
  const done = assert.async()
  const root = document.getElementById('fixtures')
  root.innerHTML = `
    <img id="i1"
      class="equation_image"
      src="https://www.instructure.com/themes/instructure_blog/images/logo.svg?_time=${Date.now()}"
    >
    <img id="i2"
      class="equation_image"
      src="data:image/gif;base64,R0lGODdhDAAMAIABAMzMzP///ywAAAAADAAMAAACFoQfqYeabNyDMkBQb81Uat85nxguUAEAOw=="
    >
  `

  window.setTimeout(() => {
    mathImageHelper.catchEquationImages(root)
    equal(document.querySelectorAll('img[mathjaxified]').length, 1)
    done()
  }, 0)
})

test('catchEquationImages defers processing images until loaded', assert => {
  const done = assert.async()
  const root = document.getElementById('fixtures')
  const spy = sinon.spy(mathImageHelper, 'dispatchProcessNewMathOnLoad')
  root.innerHTML = `
    <img id="i1"
      class="equation_image"
      data-equation-content="x"
      src="https://www.instructure.com/themes/instructure_blog/images/logo.svg?_time=${Date.now()}"
    >
  `
  mathImageHelper.catchEquationImages(root)
  equal(document.querySelectorAll('img[mathjaxified]').length, 0)
  equal(spy.callCount, 0)
  document
    .getElementById('i1')
    .setAttribute(
      'src',
      'data:image/gif;base64,R0lGODdhDAAMAIABAMzMzP///ywAAAAADAAMAAACFoQfqYeabNyDMkBQb81Uat85nxguUAEAOw=='
    )

  window.setTimeout(() => {
    equal(spy.callCount, 1)
    done()
  }, 0)
})

test('removeStrayEquationImages only removes tagged images', () => {
  const root = document.getElementById('fixtures')
  root.innerHTML = `
    <img id="i1" class="equation_image">
    <img id="i2" class="equation_image" mathjaxified>
  `
  mathImageHelper.removeStrayEquationImages(root)

  ok(document.getElementById('i1'))
  equal(document.getElementById('i2'), null)
})

QUnit.module('isMathJaxIgnored', {
  beforeEach: () => {
    window.ENV = {
      FEATURES: {
        new_math_equation_handling: true,
        inline_math_everywhere: true
      }
    }
    document.getElementById('fixtures').innerHTML = ''
  },
  afterEach: () => {
    document.getElementById('fixtures').innerHTML = ''
  }
})

test('ignores elements in the ignore list', () => {
  const root = document.getElementById('fixtures')
  const elem = document.createElement('span')
  elem.setAttribute('id', 'quiz-elapsed-time')
  root.appendChild(elem)
  ok(mathml.isMathJaxIgnored(elem))
})

test('ignores descendents of .mathjax_ignore', () => {
  const root = document.getElementById('fixtures')
  const ignored = document.createElement('span')
  ignored.setAttribute('class', 'mathjax_ignore')
  root.appendChild(ignored)
  const elem = document.createElement('span')
  elem.textContent = 'ignore me'
  ignored.appendChild(elem)
  ok(mathml.isMathJaxIgnored(elem))
})
