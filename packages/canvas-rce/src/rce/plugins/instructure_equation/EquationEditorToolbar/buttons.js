/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import formatMessage from '../../../../format-message'

export default [
  {
    name: formatMessage('Basic'),
    commands: [
      {
        displayName: 'x_{\u2B1A}^{\\ }',
        command: '_{\\placeholder{}}',
        advancedCommand: '_',
        svgCommand: 'x_{\\square}'
      },
      {
        displayName: 'x^{\u2B1A}_{\\ }',
        command: '^{\\placeholder{}}',
        advancedCommand: '^',
        svgCommand: 'x^{\\square}'
      },
      {
        displayName: '\\frac{\u2B1A}{\u2B1A}',
        command: '\\frac{\\placeholder{}}{\\placeholder{}}',
        advancedCommand: '\\frac{ }{ }',
        svgCommand: '\\frac{\\square}{\\square}'
      },
      {
        displayName: '\\sqrt{\\ }',
        command: '\\sqrt{\\placeholder{}}',
        advancedCommand: '\\sqrt{ }'
      },
      {
        displayName: '\\sqrt[n]{\\ }',
        command: '\\sqrt[\\placeholder{}]{\\placeholder{}}',
        advancedCommand: '\\sqrt[ ]{ }',
        svgCommand: '\\sqrt[n]{ }'
      },
      {command: '\\langle'},
      {command: '\\rangle'},
      {
        displayName: '\\binom{n}{m}',
        command: '\\binom{\\placeholder{}}{\\placeholder{}}',
        advancedCommand: '\\binom{ }{ }',
        svgCommand: '\\binom{n}{m}'
      },
      // TODO maybe re-add vector, after figuring out if it even works
      {command: 'f'},
      {command: '\\prime'},
      {command: '+'},
      {command: '-'},
      {command: '\\pm'},
      {command: '\\mp'},
      {command: '\\cdot'},
      {command: '='},
      {command: '\\times'},
      {command: '\\div'},
      {command: '\\ast'},
      {command: '\\therefore'},
      {command: '\\because'},
      {
        displayName: '\\sum_{\\ }^{\\ }',
        command: '\\sum_{\\placeholder{}}^{\\placeholder{}}',
        advancedCommand: '\\sum_{ }^{ }',
        svgCommand: '\\sum'
      },
      {
        displayName: '\\prod_{\\ }^{\\ }',
        command: '\\prod_{\\placeholder{}}^{\\placeholder{}}',
        advancedCommand: '\\prod_{ }^{ }',
        svgCommand: '\\prod'
      },
      {
        displayName: '\\coprod_{\\ }^{\\ }',
        command: '\\coprod_{\\placeholder{}}^{\\placeholder{}}',
        advancedCommand: '\\coprod_{ }^{ }',
        svgCommand: '\\coprod'
      },
      {
        displayName: '\\int_{\\ }^{\\ }',
        command: '\\int_{\\placeholder{}}^{\\placeholder{}}',
        advancedCommand: '\\int_{ }^{ }',
        svgCommand: '\\int'
      },
      {command: '\\mathbb{N}'},
      {command: '\\mathbb{P}'},
      {command: '\\mathbb{Z}'},
      {command: '\\mathbb{Q}'},
      {command: '\\mathbb{R}'},
      {command: '\\mathbb{C}'},
      {command: '\\mathbb{H}'}
    ]
  },

  {
    name: formatMessage('Greek'),
    commands: [
      {command: '\\alpha'},
      {command: '\\beta'},
      {command: '\\gamma'},
      {command: '\\delta'},
      {command: '\\epsilon'},
      {command: '\\zeta'},
      {command: '\\eta'},
      {command: '\\theta'},
      {command: '\\iota'},
      {command: '\\kappa'},
      {command: '\\lambda'},
      {command: '\\mu'},
      {command: '\\nu'},
      {command: '\\xi'},
      {command: '\\pi'},
      {command: '\\rho'},
      {command: '\\sigma'},
      {command: '\\tau'},
      {command: '\\upsilon'},
      {command: '\\phi'},
      {command: '\\chi'},
      {command: '\\psi'},
      {command: '\\omega'},
      {command: '\\digamma'},
      {command: '\\varepsilon'},
      {command: '\\vartheta'},
      {command: '\\varkappa'},
      {command: '\\varpi'},
      {command: '\\varrho'},
      {command: '\\varsigma'},
      {command: '\\varphi'},
      {command: '\\Gamma'},
      {command: '\\Delta'},
      {command: '\\Theta'},
      {command: '\\Lambda'},
      {command: '\\Xi'},
      {command: '\\Pi'},
      {command: '\\Sigma'},
      {command: '\\Upsilon'},
      {command: '\\Phi'},
      {command: '\\Psi'},
      {command: '\\Omega'}
    ]
  },

  {
    name: formatMessage('Operators'),
    commands: [
      {command: '\\wedge'},
      {command: '\\vee'},
      {command: '\\cup'},
      {command: '\\cap'},
      {command: '\\diamond'},
      {command: '\\bigtriangleup'},
      {command: '\\ominus'},
      {command: '\\uplus'},
      {command: '\\otimes'},
      {command: '\\oplus'},
      {command: '\\bigtriangledown'},
      {command: '\\sqcap'},
      {command: '\\triangleleft'},
      {command: '\\sqcup'},
      {command: '\\triangleright'},
      {command: '\\odot'},
      {command: '\\bigcirc'},
      {command: '\\dagger'},
      {command: '\\ddagger'},
      {command: '\\wr'},
      {command: '\\amalg'}
    ]
  },

  {
    name: formatMessage('Relationships'),
    commands: [
      {command: '<'},
      {command: '>'},
      {command: '\\equiv'},
      {command: '\\cong'},
      {command: '\\sim'},
      {command: '\\notin'},
      {command: '\\ne'},
      {command: '\\propto'},
      {command: '\\approx'},
      {command: '\\le'},
      {command: '\\ge'},
      {command: '\\in'},
      {command: '\\ni'},
      // TODO consider reenabling once mathlive supports it
      // { command: '\\notni' },
      {command: '\\subset'},
      {command: '\\supset'},
      {command: '\\not\\subset'},
      {command: '\\not\\supset'},
      {command: '\\subseteq'},
      {command: '\\supseteq'},
      {command: '\\not\\subseteq'},
      {command: '\\not\\supseteq'},
      {command: '\\models'},
      {command: '\\prec'},
      {command: '\\succ'},
      {command: '\\preceq'},
      {command: '\\succeq'},
      {command: '\\simeq'},
      {command: '\\mid'},
      {command: '\\ll'},
      {command: '\\gg'},
      {command: '\\parallel'},
      {command: '\\bowtie'},
      {command: '\\sqsubset'},
      {command: '\\sqsupset'},
      {command: '\\smile'},
      {command: '\\sqsubseteq'},
      {command: '\\sqsupseteq'},
      {command: '\\doteq'},
      {command: '\\frown'},
      {command: '\\vdash'},
      {command: '\\dashv'},
      {command: '\\exists'},
      {command: '\\varnothing'}
    ]
  },

  {
    name: formatMessage('Arrows'),
    commands: [
      {command: '\\longleftarrow'},
      {command: '\\longrightarrow'},
      {command: '\\Longleftarrow'},
      {command: '\\Longrightarrow'},
      {command: '\\longleftrightarrow'},
      {command: '\\updownarrow'},
      {command: '\\Longleftrightarrow'},
      {command: '\\Updownarrow'},
      {command: '\\mapsto'},
      {command: '\\nearrow'},
      {command: '\\hookleftarrow'},
      {command: '\\hookrightarrow'},
      {command: '\\searrow'},
      {command: '\\leftharpoonup'},
      {command: '\\rightharpoonup'},
      {command: '\\swarrow'},
      {command: '\\leftharpoondown'},
      {command: '\\rightharpoondown'},
      {command: '\\nwarrow'},
      {command: '\\downarrow'},
      {command: '\\Downarrow'},
      {command: '\\uparrow'},
      {command: '\\Uparrow'},
      {command: '\\rightarrow'},
      {command: '\\Rightarrow'},
      {command: '\\leftarrow'},
      {command: '\\Leftarrow'},
      {command: '\\leftrightarrow'},
      {command: '\\Leftrightarrow'}
    ]
  },

  {
    name: formatMessage('Delimiters'),
    commands: [
      {command: '\\lfloor'},
      {command: '\\rfloor'},
      {command: '\\lceil'},
      {command: '\\rceil'},
      {command: '/'},
      {command: '\\lbrace'},
      {command: '\\rbrace'}
    ]
  },

  {
    name: formatMessage('Misc'),
    commands: [
      {command: '\\forall'},
      {command: '\\ldots'},
      {command: '\\cdots'},
      {command: '\\vdots'},
      {command: '\\ddots'},
      {command: '\\surd'},
      {command: '\\triangle'},
      {command: '\\ell'},
      {command: '\\top'},
      {command: '\\flat'},
      {command: '\\natural'},
      {command: '\\sharp'},
      {command: '\\wp'},
      {command: '\\bot'},
      {command: '\\clubsuit'},
      {command: '\\diamondsuit'},
      {command: '\\heartsuit'},
      {command: '\\spadesuit'},
      // TODO maybe readd caret, underscore once I figure out if they even worked
      {command: '\\backslash'},
      {command: '\\vert'},
      {command: '\\perp'},
      {command: '\\nabla'},
      {command: '\\hbar'},
      // TODO consider renabling if we can not get stuck in text mode
      // { command: '\\text\\AA' },
      {command: '\\circ'},
      {command: '\\bullet'},
      {command: '\\setminus'},
      {command: '\\neg'},
      // TODO consider reenabling once mathlive supports it
      // { command: '\\dots' },
      {command: '\\Re'},
      {command: '\\Im'},
      {command: '\\partial'},
      {command: '\\infty'},
      {command: '\\aleph'},
      {command: '^\\circ'}, // \\deg requires the gensymb package added to LaTex
      {command: '\\angle'}
    ]
  }
]
