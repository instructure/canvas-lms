/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

'use strict'

const fs = require('fs')
const path = require('path')

const year = new Date().getFullYear()
const templatePath = path.join(__dirname, 'copyright-template.js')
const header = fs.readFileSync(templatePath, 'utf8').replace('<%= YEAR %>', year)

module.exports = {
  meta: {name: 'canvas-copyright'},
  rules: {
    notice: {
      meta: {
        type: 'suggestion',
        fixable: 'code',
        schema: [],
      },
      create(context) {
        return {
          Program(node) {
            const src = context.sourceCode.getText()
            if (!src.includes('Copyright ')) {
              context.report({
                node,
                message: 'Missing copyright header.',
                fix(fixer) {
                  return fixer.insertTextBefore(node, header + '\n')
                },
              })
            }
          },
        }
      },
    },
  },
}
