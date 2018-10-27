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

export function loadMathJax (configFile, cb = null) {
  if (!isMathJaxLoaded()) {
    // signal local config to mathjax as it loads
    window.MathJax = localConfig;
    $.getScript(`//cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js?config=${configFile}`, cb);
  } else if (typeof cb === 'function') {
      // Make sure we always call the callback if it is loaded already and make sure we
      // also reprocess the page since chances are if we are requesting MathJax again,
      // something has changed on the page and needs to get pulled into the MathJax ecosystem
      window.MathJax.Hub.Reprocess();
      cb();
  }
}

export function isMathMLOnPage () {
  const mathElements = $('math:visible').toArray();
  return mathElements.some(elem => $(elem).parent('.hidden-readable').length <= 0);
}

export function isMathJaxLoaded () {
  return !(typeof MathJax === 'undefined')
}

/*
 * elem: string with elementId or en elem object
 */
export function reloadElement(elem) {
  if (window.MathJax) {
    window.MathJax.Hub.Queue(['Typeset', window.MathJax.Hub, elem])
  }
}
