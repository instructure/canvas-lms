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

export function loadMathJax (config_file, cb = null) {
  if (!isMathJaxLoaded()) {
    $.getScript(`//cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js?config=${config_file}`, cb);
  }
}

export function isMathMLOnPage () {
  return $('math').length > 0
}

export function isMathJaxLoaded () {
  return !(typeof MathJax === 'undefined')
}

/*
 * elem: string with elementId or en elem object
 */
export function reloadElement(elem) {
  if (MathJax) {
    MathJax.Hub.Queue(['Typeset', MathJax.Hub, elem])
  }
}
