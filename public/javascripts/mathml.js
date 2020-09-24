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
  }
}

export function loadMathJax(configFile = 'TeX-MML-AM_HTMLorMML', cb = null) {
  if (!isMathJaxLoaded()) {
    const locale = ENV.LOCALE || 'en'
    // signal local config to mathjax as it loads
    window.MathJax = localConfig
    $.getScript(
      `//cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.5/MathJax.js?config=${configFile}&locale=${locale}`,
      () => {
        window.MathJax.Hub.Register.MessageHook('End Math', function(message) {
          message[1]
            .querySelectorAll('.math_equation_latex')
            .forEach(m => m.classList.add('fade-in-equation'))
        })

        cb?.()
      }
    )
  } else {
    // Make sure we always call the callback if it is loaded already and make sure we
    // also reprocess the page since chances are if we are requesting MathJax again,
    // something has changed on the page and needs to get pulled into the MathJax ecosystem
    window.MathJax.Hub.Reprocess()
    cb?.()
  }
}

export function isMathMLOnPage() {
  // handle the change from image + hidden mathml to mathjax formatted latex
  if (document.querySelector('.math_equation_latex')) {
    return true
  }
  const mathElements = document.getElementsByTagName('math')
  for (let i = 0; i < mathElements.length; i++) {
    const $el = $(mathElements[i])
    if ($el.is(':visible') && $el.parent('.hidden-readable').length <= 0) return true
  }
}

export function isMathJaxLoaded() {
  return !!window.MathJax?.Hub
}

/*
 * elem: string with elementId or en elem object
 */
export function reloadElement(elem) {
  if (isMathJaxLoaded()) {
    window.MathJax.Hub.Queue(['Typeset', window.MathJax.Hub, elem])
  }
}
