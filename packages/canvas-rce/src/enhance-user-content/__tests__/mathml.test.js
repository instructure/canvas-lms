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

import {Mathml, mathImageHelper, MathJaxDirective} from '../mathml'

let stub = null
describe('MathML and MathJax it', () => {
  let mathml

  beforeEach(() => {
    mathml = new Mathml()
  })

  afterEach(() => {
    jest.clearAllMocks()
    stub = null
    delete window.MathJax
    delete window.MathJaxIsLoading
    document.body.innerHTML = ''
    document.head.innerHTML = ''
  })

  it('loadMathJax loads mathJax', () => {
    mathml.loadMathJax('bogus')
    expect(
      Array.from(document.querySelectorAll('script[src]')).filter(el =>
        el.src.includes('//cdnjs.cloudflare.com/ajax/libs/mathjax')
      ).length
    ).toEqual(1)
  })

  it('loadMathJax does not load mathJax if already loaded', () => {
    // this exists if mathjax has already loaded successfully
    window.MathJax = {
      Hub: {
        Queue: () => {},
      },
    }
    mathml.loadMathJax('bogus')
    expect(
      Array.from(document.querySelectorAll('script[src]')).filter(el =>
        el.src.includes('//cdnjs.cloudflare.com/ajax/libs/mathjax')
      ).length
    ).toEqual(0)
  })

  it("loadMathJax doesn't download mathjax if in-flight", () => {
    mathml.loadMathJax('bogus')
    mathml.loadMathJax('bogus')
    expect(
      Array.from(document.querySelectorAll('script[src]')).filter(el =>
        el.src.includes('//cdnjs.cloudflare.com/ajax/libs/mathjax')
      ).length
    ).toEqual(1)
  })

  it('isMathJaxLoaded return true', () => {
    window.MathJax = {Hub: {}}
    expect(mathml.isMathJaxLoaded()).toBeTruthy()
  })

  it('reloadElement reloads the element', () => {
    window.MathJax = {
      Hub: {
        Queue: jest.fn(),
      },
    }
    mathml.reloadElement('content')
    expect(window.MathJax.Hub.Queue).toHaveBeenCalledTimes(1)
  })

  describe('explicit_latex_typesetting', () => {
    let elem

    beforeEach(() => {
      elem = document.createElement('span')
      elem.classList.add(MathJaxDirective.Process)
      document.body.appendChild(elem)
    })

    it('does not modify localConfig when disabled', () => {
      mathml = new Mathml({explicit_latex_typesetting: false}, {locale: 'en'})
      mathml.loadMathJax('bogus')
      expect(window.MathJax).not.toHaveProperty('elements')
      expect(window.MathJax.tex2jax).not.toHaveProperty('processClass')
    })

    it('modifies localConfig when enabled', () => {
      mathml = new Mathml({explicit_latex_typesetting: true}, {locale: 'en'})
      mathml.loadMathJax('bogus')
      expect(window.MathJax.elements).toContain(elem)
      expect(window.MathJax.tex2jax.processClass).toEqual(MathJaxDirective.Process)
    })
  })
})

describe('isMathInElement', () => {
  let mathml

  beforeEach(() => {
    mathml = new Mathml()
  })

  it('returns true if there is mathml', () => {
    const mathElem = document.createElement('div')
    mathElem.innerHTML = '<math><mi>&#x3C0;</mi> <msup> <mi>r</mi> <mn>2</mn> </msup></math>'
    document.body.innerHTML = mathElem.outerHTML
    expect(mathml.isMathInElement(mathElem)).toBeTruthy()
  })

  it('returns false if there is a .math_equation_latex element', () => {
    const mathElem = document.createElement('span')
    mathElem.innerHTML = '<span class="math_equation_latex">2 + 2</span>'

    document.body.innerHTML = mathElem.outerHTML
    expect(mathml.isMathInElement(mathElem)).toBeFalsy()
  })
})

describe('isMathInElement, with new_math_equation_handling on', () => {
  let mathml

  beforeEach(() => {
    mathml = new Mathml({new_math_equation_handling: true})
  })

  it('returns true if there is mathml', () => {
    const mathElem = document.createElement('span')
    mathElem.innerHTML = '<math><mi>&#x3C0;</mi> <msup> <mi>r</mi> <mn>2</mn> </msup>></math>'
    document.body.innerHTML = mathElem.outerHTML
    expect(mathml.isMathInElement(mathElem)).toBeTruthy()
  })

  it('returns true if there is a .math_equation_latex element', () => {
    const mathElem = document.createElement('span')
    mathElem.innerHTML = '<span class="math_equation_latex">2 + 2</span>'

    document.body.innerHTML = mathElem.outerHTML
    expect(mathml.isMathInElement(mathElem)).toBeTruthy()
  })

  it('returns true if there is block-delmited math', () => {
    const mathElem = document.createElement('span')
    mathElem.innerHTML = '$$y = mx + b$$'
    document.body.innerHTML = mathElem.outerHTML
    expect(mathml.isMathInElement(mathElem)).toBeTruthy()
  })

  it('returns true if there is inline-delmited math', () => {
    const mathElem = document.createElement('span')
    mathElem.innerHTML = '\\(ax^2 + by + c = 0\\)'
    document.body.innerHTML = mathElem.outerHTML
    expect(mathml.isMathInElement(mathElem)).toBeTruthy()
  })

  it('handles "process-new-math" event', () => {
    stub = jest.spyOn(Mathml.prototype, 'processNewMathInElem')
    const elem = document.createElement('span')
    window.dispatchEvent(
      new CustomEvent(Mathml.processNewMathEventName, {
        detail: {
          target: elem,
          features: {new_math_equation_handling: true},
        },
      })
    )
    expect(stub).toHaveBeenCalledWith(elem)
  })
})

describe('mathEquationHelper', () => {
  beforeEach(() => {
    document.body.innerHTML = ''
  })

  afterEach(() => {
    document.body.innerHTML = ''
  })

  it('getImageEquationText does not use data-equation-content', () => {
    const img = document.createElement('img')
    const txt = encodeURIComponent(encodeURIComponent('y = sqrt{x}'))
    img.setAttribute('src', `http://host/equation_images/${txt}`)
    img.setAttribute('data-equation-content', 'never use me')
    expect(mathImageHelper.getImageEquationText(img)).toEqual('y = sqrt{x}')
  })

  it('getImageEquationText uses img src as the source of truth', () => {
    const img = document.createElement('img')
    const txt = encodeURIComponent(encodeURIComponent('y = sqrt{x}'))
    img.setAttribute('src', `http://host/equation_images/${txt}`)
    img.setAttribute('data-equation-content', 'never use me')
    expect(mathImageHelper.getImageEquationText(img)).toEqual('y = sqrt{x}')
  })

  it('getImageEquationText returns undefined if there is no src', () => {
    const img = document.createElement('img')
    const txt = encodeURIComponent(encodeURIComponent('y = sqrt{x}'))
    img.setAttribute('alt', `http://host/not_equation_images/${txt}`)
    expect(mathImageHelper.getImageEquationText(img)).toBeUndefined()
  })

  it('getImageEquationText returns undefined if it is not an equation image', () => {
    const img = document.createElement('img')
    const txt = encodeURIComponent(encodeURIComponent('y = sqrt{x}'))
    img.setAttribute('src', `http://host/not_equation_images/${txt}`)
    expect(mathImageHelper.getImageEquationText(img)).toBeUndefined()
  })

  it('catchEquationImages processes equation images', () => {
    const root = document.body
    root.innerHTML = `
      <img id="i2"
        class="equation_image"
        src="data:image/gif;base64,R0lGODdhDAAMAIABAMzMzP///ywAAAAADAAMAAACFoQfqYeabNyDMkBQb81Uat85nxguUAEAOw=="
      >
      <img id="i2"
        class="equation_image"
        src="http://localhost:3000/equation_images/17?scale=1.5"
      >
    `
    mathImageHelper.catchEquationImages(root)
    expect(document.querySelectorAll('img[mathjaxified]').length).toEqual(1)
    expect(document.querySelector('.math_equation_latex').textContent).toEqual('\\(17\\)')
  })

  it('catchEquationImages doesnt break with an array of equation images', () => {
    const root = document.body
    root.innerHTML = `
      <img id="i2"
        class="equation_image"
        src="http://localhost:3000/equation_images/17?scale=1.5"
      >
    `
    const otherhtml = `
      <img id="i3"
        class="equation_image"
        src="http://localhost:3000/equation_images/17?scale=1.5"
      >
    `
    const imgarr = [root, otherhtml]
    expect(mathImageHelper.catchEquationImages(imgarr)).toBeTruthy()
    expect(document.querySelectorAll('img[mathjaxified]').length).toEqual(1)
    expect(document.querySelector('.math_equation_latex').textContent).toEqual('\\(17\\)')
  })

  it('removeStrayEquationImages only removes tagged images', () => {
    const root = document.body
    root.innerHTML = `
      <img id="i1" class="equation_image">
      <img id="i2" class="equation_image" mathjaxified>
    `
    mathImageHelper.removeStrayEquationImages(root)

    expect(document.getElementById('i1')).toBeTruthy()
    expect(document.getElementById('i2')).toBeNull()
  })
})

describe('isMathJaxIgnored', () => {
  let mathml

  beforeEach(() => {
    document.body.innerHTML = ''
    mathml = new Mathml()
  })

  afterEach(() => {
    document.body.innerHTML = ''
  })

  it('ignores elements in the ignore list', () => {
    const root = document.body
    const elem = document.createElement('span')
    elem.setAttribute('id', 'quiz-elapsed-time')
    root.appendChild(elem)
    expect(mathml.isMathJaxIgnored(elem)).toBeTruthy()
  })

  it('ignores descendents of ignored elements', () => {
    const root = document.body
    const ignored = document.createElement('span')
    ignored.setAttribute('class', MathJaxDirective.Ignore)
    root.appendChild(ignored)
    const elem = document.createElement('span')
    elem.textContent = 'ignore me'
    ignored.appendChild(elem)
    expect(mathml.isMathJaxIgnored(elem)).toBeTruthy()
  })

  it('deals with disconnected elements', () => {
    // even though they should never get here
    const elem = document.createElement('span')
    expect(mathml.isMathJaxIgnored(elem)).toBeTruthy()
  })

  it('handles missing element', () => {
    expect(mathml.isMathJaxIgnored()).toBeTruthy()
  })

  it('by default does not ignore elements without the process directive class', () => {
    const elem = document.createElement('span')
    document.body.appendChild(elem)
    expect(mathml.isMathJaxIgnored(elem)).toBeFalsy()
  })

  describe('when explicit_latex_typesetting is on', () => {
    beforeEach(() => {
      mathml = new Mathml({explicit_latex_typesetting: true})
    })

    it('ignores elements without the process directive class', () => {
      const elem = document.createElement('span')
      document.body.appendChild(elem)
      expect(mathml.isMathJaxIgnored(elem)).toBeTruthy()
    })

    it('does not ignore elements with the process directive class', () => {
      const elem = document.createElement('span')
      document.body.appendChild(elem)
      elem.classList.add(MathJaxDirective.Process)
      expect(mathml.isMathJaxIgnored(elem)).toBeFalsy()
    })
  })
})
