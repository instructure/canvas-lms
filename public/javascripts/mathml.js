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
    extensions: ["color.js"]
  }
};

export function loadMathJax (config_file, cb = null) {
  if (!isMathJaxLoaded() && shouldLoadMathJax()) {
    // signal local config to mathjax as it loads
    window.MathJax = localConfig;
    $.getScript(`//cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js?config=${config_file}`, cb);
  }
}

export function isMathMLOnPage () {
  return $('math').length > 0
}

export function isMathJaxLoaded () {
  return !(typeof MathJax === 'undefined')
}

export function shouldLoadMathJax() {
  return ($(document.documentElement).find("img.equation_image").length <= 0)
}

/*
 * elem: string with elementId or en elem object
 */
export function reloadElement(elem) {
  if (MathJax) {
    MathJax.Hub.Queue(['Typeset', MathJax.Hub, elem])
  }
}
