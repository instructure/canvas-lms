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
// this copy of lodash is already in the webpack chunk
// (something to do with backbone compatability)
// if I simply import {debounce} from 'lodash', then there are 2 copies
// and the chunk exceeds our size limit.
import {debounce} from './vendor/lodash.underscore'

// configure MathJax to use 'color' extension fo LaTeX coding
const localConfig = {
  TeX: {
    extensions: ['color.js']
  },
  tex2jax: {
    ignoreClass: 'mathjax_ignore'
  },
  extensions: ['Safe.js'],
  Safe: {
    safeProtocols: {http: true, https: true, file: false, javascript: false, data: false}
  },
  MathMenu: {
    styles: {
      '.MathJax_Menu': {'z-index': 2001}
    }
  },
  showMathMenu: true
}

const mathml = {
  loadMathJax(configFile = 'TeX-MML-AM_HTMLorMML', cb = null) {
    if (!this.isMathJaxLoaded()) {
      const locale = ENV.LOCALE || 'en'
      // signal local config to mathjax as it loads
      window.MathJax = localConfig
      if (window.MathJaxIsLoading) return
      window.MathJaxIsLoading = true
      $.ajax({
        url: `//cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.7/MathJax.js?config=${configFile}&locale=${locale}`,
        cache: true,
        success: () => {
          window.MathJax.Hub.Register.StartupHook('MathMenu Ready', function() {
            // get the mathjax context menu above the rce's equation editor
            window.MathJax.Menu.BGSTYLE['z-index'] = 2000
          })
          window.MathJax.Hub.Register.StartupHook('End Config', function() {
            // wait until MathJAx is configured before calling the callback
            cb?.()
          })
          window.MathJax.Hub.Register.MessageHook('Begin PreProcess', function(message) {
            mathImageHelper.catchEquationImages(message[1])
          })
          window.MathJax.Hub.Register.MessageHook('End Math', function(message) {
            mathImageHelper.removeStrayEquationImages(message[1])
            message[1]
              .querySelectorAll('.math_equation_latex')
              .forEach(m => m.classList.add('fade-in-equation'))
          })
          // leaving this here so I don't have to keep looking up how to see all messages
          // window.MathJax.Hub.Startup.signal.Interest(function (message) {
          //   console.log('>>> Startup:', message[0])
          // })
          // window.MathJax.Hub.signal.Interest(function(message) {
          //   console.log('>>> ', message[0])
          // })
          delete window.MathJaxIsLoading
        },
        dataType: 'script'
      })
    } else {
      // Make sure we always call the callback if it is loaded already and make sure we
      // also reprocess the page since chances are if we are requesting MathJax again,
      // something has changed on the page and needs to gReprocess(document.body)et pulled into the MathJax ecosystem
      // window.MathJax.Hub.Reprocess([document.body])
      window.MathJax.Hub.Queue(['Typeset', window.MathJax.Hub])
      cb?.()
    }
  },

  isMathOnPage() {
    if (ENV?.FEATURES?.new_math_equation_handling) {
      // handle the change from image + hidden mathml to mathjax formatted latex
      if (document.querySelector('.math_equation_latex')) {
        return true
      }

      if (document.querySelector('img.equation_image')) {
        return true
      }

      if (ENV.FEATURES?.inline_math_everywhere) {
        // look for latex the user may have entered w/o the equation editor by
        // looking for mathjax's opening delimiters
        if (/(?:\$\$|\\\()/.test(document.body.textContent)) {
          return true
        }
      }
    }
    const mathElements = document.getElementsByTagName('math')
    for (let i = 0; i < mathElements.length; i++) {
      const $el = $(mathElements[i])
      if ($el.is(':visible') && $el.parent('.hidden-readable').length <= 0) {
        return true
      }
    }
    return false
  },

  isMathMLOnPage() {
    return this.isMathOnPage() // just in case I missed a place it's being used
  },

  isMathJaxLoaded() {
    return !!window.MathJax?.Hub
  },

  processNewMathOnPage() {
    if (this.isMathOnPage()) {
      this.loadMathJax(undefined)
    }
  },

  /*
   * elem: string with elementId or en elem object
   */
  reloadElement(elem) {
    if (this.isMathJaxLoaded()) {
      window.MathJax.Hub.Queue(['Typeset', window.MathJax.Hub, elem])
    }
  },

  processNewMathEventName: 'process-new-math'
}

const mathImageHelper = {
  catchEquationImages(refnode) {
    // find equation images and replace with inline LaTeX
    const eqimgs = refnode.querySelectorAll('img.equation_image')
    if (eqimgs.length > 0) {
      eqimgs.forEach(img => {
        if (img.complete) {
          // only process loaded images
          img.setAttribute('mathjaxified', '')
          const equation_text = img.getAttribute('data-equation-content')
          const mathtex = document.createElement('span')
          mathtex.setAttribute('class', 'math_equation_latex')
          mathtex.textContent = `\\(${equation_text}\\)`
          if (img.nextSibling) {
            img.parentElement.insertBefore(mathtex, img.nextSibling)
          } else {
            img.parentElement.appendChild(mathtex)
          }
        } else {
          img.addEventListener('load', this.dispatchProcessNewMathOnLoad)
        }
      })
      return true
    }
  },

  removeStrayEquationImages(refnode) {
    const eqimgs = refnode.querySelectorAll('img.equation_image')
    eqimgs.forEach(img => {
      if (img.hasAttribute('mathjaxified')) {
        img.parentElement.removeChild(img)
      }
    })
  },

  dispatchProcessNewMathOnLoad(event) {
    event.target.removeEventListener('load', this.dispatchProcessNewMathOnLoad)
    window.dispatchEvent(new Event('process-new-math'))
  }
}

// TODO: if anyone firing the event ever needs a callback,
// push them onto an array, then pop and call in the handler
function handleNewMath() {
  if (ENV?.FEATURES?.new_math_equation_handling) {
    mathml.processNewMathOnPage()
  }
}

window.addEventListener('process-new-math', debounce(handleNewMath, 500))

export {mathml as default, mathImageHelper}
