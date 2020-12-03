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
          if (ENV?.FEATURES?.new_math_equation_handling) {
            window.MathJax.Hub.Register.MessageHook('Begin PreProcess', function(message) {
              mathImageHelper.catchEquationImages(message[1])
            })
            window.MathJax.Hub.Register.MessageHook('End Math', function(message) {
              mathImageHelper.removeStrayEquationImages(message[1])
              message[1]
                .querySelectorAll('.math_equation_latex')
                .forEach(m => m.classList.add('fade-in-equation'))
            })
          }
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
    return this.isMathInElement(document.body)
  },

  isMathInElement(elem) {
    if (ENV?.FEATURES?.new_math_equation_handling) {
      // handle the change from image + hidden mathml to mathjax formatted latex
      if (elem.querySelector('.math_equation_latex')) {
        return true
      }

      if (elem.querySelector('img.equation_image')) {
        return true
      }

      if (ENV.FEATURES?.inline_math_everywhere) {
        // look for latex the user may have entered w/o the equation editor by
        // looking for mathjax's opening delimiters
        if (/(?:\$\$|\\\()/.test(elem.textContent)) {
          return true
        }
      }
    }
    const mathElements = elem.getElementsByTagName('math')
    for (let i = 0; i < mathElements.length; i++) {
      const $el = $(mathElements[i])
      if (
        $el.is(':visible') &&
        $el.parent('.hidden-readable').length <= 0 &&
        $el.parent('.MJX_Assistive_MathML').length <= 0 // already mathjax'd
      ) {
        return true
      }
    }
    return false
  },

  isMathJaxIgnored(elem) {
    // elements to ignore selector
    const ignore_list =
      '.MJX_Assistive_MathML,#header,#mobile-header,#left-side,#quiz-elapsed-time,.ui-menu-carat'

    // check if elem is in the ignore list
    if (elem.parentElement.querySelector(ignore_list) === elem) {
      return true
    }

    // check if elem is a child of .mathjax_ignore
    while (elem !== document.body) {
      if (elem.classList.contains('mathjax_ignore')) {
        return true
      }
      elem = elem.parentElement
    }
    return false
  },

  // legacy api
  isMathMLOnPage() {
    return this.isMathOnPage()
  },

  isMathJaxLoaded() {
    return !!window.MathJax?.Hub
  },

  processNewMathInElem(elem) {
    if (this.isMathInElement(elem) && !this.isMathJaxIgnored(elem)) {
      if (this.isMathJaxLoaded()) {
        this.reloadElement(elem)
      } else {
        this.loadMathJax(undefined)
      }
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
  getImageEquationText(img) {
    let equation_text = img.getAttribute('data-equation-content')
    if (!equation_text) {
      const srceq = img.getAttribute('src').split('/equation_images/')[1]
      if (srceq) {
        equation_text = decodeURIComponent(decodeURIComponent(srceq))
      }
    }
    return equation_text
  },

  catchEquationImages(refnode) {
    // find equation images and replace with inline LaTeX
    const eqimgs = refnode.querySelectorAll('img.equation_image')
    if (eqimgs.length > 0) {
      eqimgs.forEach(img => {
        if (img.complete && img.naturalWidth) {
          // only process loaded images
          img.setAttribute('mathjaxified', '')
          const equation_text = this.getImageEquationText(img)
          if (equation_text) {
            const mathtex = document.createElement('span')
            mathtex.setAttribute('class', 'math_equation_latex')
            mathtex.textContent = `\\(${equation_text}\\)`
            if (img.nextSibling) {
              img.parentElement.insertBefore(mathtex, img.nextSibling)
            } else {
              img.parentElement.appendChild(mathtex)
            }
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
    window.dispatchEvent(
      new CustomEvent('process-new-math', {detail: {target: event.target.parentElement}})
    )
  }
}

function handleNewMath(event) {
  if (event?.detail?.target) {
    mathml.processNewMathInElem(event.detail.target)
  }
}

window.addEventListener('process-new-math', handleNewMath)

export {mathml as default, mathImageHelper}
