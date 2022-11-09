/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {memoize} from 'lodash'

// These commands all work fine with MathJax but either don't work, don't work well
// (bad UX for editing), or look strange when rendered by Mathlive. Add new ones
// here if you discover anything else or customers report unexpected experiences.
const advancedOnlyCommands = [
  'begin',
  'end',
  'cases',
  'cr',
  'rm',
  'text',
  'hbox',
  'mbox',
  'unicode',
  'cal',
  'frak',
  'it',
  'scr',
  'sf',
  '#',
  'def',
  'newcommand',
  'operatorname',
  'DeclareMathOperator',
  'displaystyle',
  'textstyle',
  'scriptstyle',
  'scriptscriptstyle',
  'displaylines',
  'abovewithdelims',
  'array',
  'bmatrix',
  'buildrel',
  'ddddot',
  'dddot',
  'eqalign',
  'eqalignno',
  'gcd',
  'genfrac',
  'hdashline',
  'hfil',
  'hfill',
  'hfilll',
  'hline',
  'idotsint',
  'iiiint',
  'injlim',
  'kern',
  'label',
  'LaTeX',
  'leftroot',
  'lgroup',
  'lower',
  'mathchoice',
  'mathfrak',
  'matrix',
  'mit',
  'mkern',
  'mspace',
  'negmedspace',
  'negthickspace',
  'negthinspace',
  'newline',
  'nobreakspace',
  'oldstyle',
  'overset',
  'pmatrix',
  'raise',
  'rgroup',
  'rule',
  'Rule',
  'skew',
  'space',
  'tag',
  'TeX',
  'underbrace',
  'uproot',
  'varinjlim',
  'varliminf',
  'varlimsup',
  'varprojlim',
  'vcenter',
  'vmatrix',
]

const advancedOnlyRegex = new RegExp(advancedOnlyCommands.join('|'), 'm')

const containsAdvancedSyntax = memoize(latex => advancedOnlyRegex.test(latex))

export {advancedOnlyCommands, containsAdvancedSyntax}
