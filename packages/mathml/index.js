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
    extensions: ['autoload-all.js']
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
    if (this.preventMathJax()) {
      return
    }
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
          window.MathJax.Hub.Register.StartupHook('MathMenu Ready', function () {
            // get the mathjax context menu above the rce's equation editor
            window.MathJax.Menu.BGSTYLE['z-index'] = 2000
          })
          window.MathJax.Hub.Register.StartupHook('End Config', function () {
            // wait until MathJAx is configured before calling the callback
            cb?.()
          })
          if (ENV?.FEATURES?.new_math_equation_handling) {
            window.MathJax.Hub.Register.MessageHook('Begin PreProcess', function (message) {
              mathImageHelper.catchEquationImages(message[1])
            })
            window.MathJax.Hub.Register.MessageHook('Math Processing Error', function (message) {
              const elem = message[1]
              // ".math_equation_latex" is the elem we added for MathJax to typeset the image equation
              if (elem.parentElement?.classList.contains('math_equation_latex')) {
                // The equation we image we were trying to replace and failed is up 1 and back 1.
                // If we remove its "mathjaxified" attribute, the "End Math" handler
                // won't remove it from the DOM.
                if (elem.parentElement.previousElementSibling?.hasAttribute('mathjaxified')) {
                  elem.parentElement.previousElementSibling.removeAttribute('mathjaxified')
                }
                // remove the "math processing error" mathjax output.
                elem.parentElement.remove()
              }
            })
            window.MathJax.Hub.Register.MessageHook('End Math', function (message) {
              const elem = message[1]
              mathImageHelper.removeStrayEquationImages(elem)
              mathImageHelper.nearlyInfiniteStyleFix(elem)
              elem
                .querySelectorAll('.math_equation_latex')
                .forEach(m => m.classList.add('fade-in-equation'))
            })
          } else {
            // though isMathInElement ignores <math> w/in .hidden-readable elements,
            // MathJax does not and will process it anyway. This is a problem when
            // you open the equation editor while editing a quiz and it adds to the DOM
            // elements that will get saved with the quiz.
            // There's a feature request against MathJax (https://github.com/mathjax/MathJax/issues/505)
            // to add an ignoreClass config prop to the mml2jax processor, but it's not available.
            // Since we want to ignore <math> in .hidden-readable spans, let's remove the MathJunk™
            // right after MathJax adds it.
            window.MathJax.Hub.Register.MessageHook('End Math', function (message) {
              $(message[1])
                .find('.hidden-readable [class^="MathJax"], .hidden-readable [id^="MathJax"]')
                .remove()
            })
          }

          // leaving this here so I don't have to keep looking up how to see all messages
          // window.MathJax.Hub.Startup.signal.Interest(function (message) {
          //   console.log('>>> MathJax startup:', message)
          // })
          // window.MathJax.Hub.signal.Interest(function(message) {
          //   console.log('>>> MathJax signal', message)
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

  preventMathJax() {
    return /(?:rubrics|\/files)/.test(window.location.pathname)
  },

  isMathOnPage() {
    return this.isMathInElement(document.body)
  },

  isMathInElement(elem) {
    if (ENV?.FEATURES?.new_math_equation_handling) {
      // handle the change from image + hidden mathml to mathjax formatted latex
      if (elem.querySelector('.math_equation_latex,.math_equation_mml')) {
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

  mathJaxGenerated: /^MathJax|MJX/,
  // elements to ignore selector
  ignore_list: '#header,#mobile-header,#left-side,#quiz-elapsed-time,.ui-menu-carat',

  isMathJaxIgnored(elem) {
    if (!elem) return true

    // ignore disconnected elements
    if (!document.body.contains(elem)) return true

    // check if elem is in the ignore list
    if (elem.parentElement?.querySelector(this.ignore_list) === elem) {
      return true
    }

    // check if elem is a child of something we're ignoring
    while (elem !== document.body) {
      // child of .mathjax_ignore?
      if (elem.classList.contains('mathjax_ignore')) {
        return true
      }

      // // child of MathJax generated element?
      // if (
      //   this.mathJaxGenerated.test(elem.id) ||
      //   this.mathJaxGenerated.test(elem.getAttribute('class'))
      // ) {
      //   return true
      // }
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
    let equation_text
    const src = img.getAttribute('src')
    if (src) {
      const srceq = src.split('/equation_images/')[1]
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
            mathtex.setAttribute('style', img.getAttribute('style'))
            mathtex.textContent = `\\(${equation_text}\\)`
            mathtex.style.maxWidth = ''
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
  },

  nearlyInfiniteStyleFix(elem) {
    elem.querySelectorAll('[style*=clip], [style*=vertical-align]').forEach(e => {
      let changed = false
      let s = e.getAttribute('style')
      const r = e.style.clip
      if (/[\d.]+e\+?\d/.test(r)) {
        // e.g. "rect(1e+07em, -9.999e+06em, -1e+07em, -999.997em)"
        s = s.replace(/clip: rect[^;]+;/, '')
        changed = true
      }
      const v = e.style.verticalAlign
      if (Math.abs(parseFloat(v)) > 10000) {
        // 10000 is a ridiculously large number
        s = s.replace(/vertical-align[^;]+;/, '')
        changed = true
      }
      if (changed) {
        e.setAttribute('style', s)
      }
    })
  }
}

function handleNewMath(event) {
  if (event?.detail?.target) {
    mathml.processNewMathInElem(event.detail.target)
  }
}

window.addEventListener('process-new-math', handleNewMath)

export {mathml as default, mathImageHelper}
