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

const t = require('./util')

module.exports = error => {
  const {request, source, target} = error

  let message = ''
  let hint = ''

  message += `\n`
  message += t.wordWrap(`Access to the following module is not allowed from this layer:`, 72)
  message += `\n \n`
  message += `    ${request}`
  message += `\n \n`
  message += `Which resolved to:`
  message += `\n \n`
  message += `    ${target}`
  message += `\n \n`

  if (source.startsWith('ui/features/') && target.startsWith('ui/features/')) {
    hint += '<Hint>'
    hint += `\n`
    hint += t.wordWrap(
      `
      Feature modules may not access different feature modules. Instead, you
      can extract the common code into a Canvas package under ui/shared/
      or into a generic package under packages/ in case it has no dependency
      on Canvas.
    `,
      60
    )
  } else if (source.startsWith('ui/shared') && target.startsWith('ui/features/')) {
    hint += '<Hint>'
    hint += `\n`
    hint += t.wordWrap(
      `
      Canvas package modules may not access feature modules. You can extract
      the desired code into another Canvas package (or your own) and access it
      as you would other Canvas packages.
    `,
      60
    )
  } else if (source.startsWith('packages/') && target.startsWith('ui/')) {
    hint += '<Hint>'
    hint += `\n`
    hint += t.wordWrap(
      `
      Package modules may not access anything under ui/, including Canvas
      packages. If this dependency is legitimate, you can 1) turn this package
      into a Canvas one where it may access other Canvas packages, or 2) extract
      the desired code into another generic package (or your own.)
    `,
      60
    )
  } else if (target.startsWith('ui/boot/')) {
    hint += `<Hint>`
    hint += `\n`
    hint += t.wordWrap(`You don't access ui/boot/, ui/boot/ accesses you.`, 60)
  }

  if (hint.length) {
    message += t.bracketize(hint)
  }

  return t.alignWithWebpackStackTrace(t.bracketize(message))
}
