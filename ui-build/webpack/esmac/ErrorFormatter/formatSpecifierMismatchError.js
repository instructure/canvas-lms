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

const micromatch = require('micromatch')
const path = require('path')
const t = require('./util')

module.exports = error => {
  const {rule, ruleIndex, request} = error

  let message = ''

  message += `\nImport violates encapsulation integrity:`
  message += `\n \n`
  message += `    ${request}`
  message += `\n \n`
  message += t.wordWrap(
    `According to rule #${ruleIndex + 1}: "${rule.rule.trim().replace(/\s+/g, ' ')}"`,
    72
  )
  message += `\n \n`

  if (rule.specifier === 'relative') {
    message += expectedRelativeSpecifier(error)
  } else if (rule.specifier === 'package') {
    message += expectedPackageSpecifier(error)
  }

  return t.alignWithWebpackStackTrace(t.bracketize(message))
}

const expectedRelativeSpecifier = ({source, target, request}) => {
  const suggestion = t.withLeadingDotSlash(
    path.relative(path.dirname(source), t.withOrWithoutExtension(request, target))
  )

  let message = ''

  message += `<Hint>`
  message += `\n`
  message += `Use a relative specifier:`
  message += `\n \n`
  message += `    ${suggestion}`
  message += `\n`

  return t.bracketize(message)
}

const expectedPackageSpecifier = error => {
  const {target} = error

  if (target.startsWith('ui/shared')) {
    // eslint-disable-next-line react-hooks/rules-of-hooks
    return useOrAddCanvasPackage(error)
  } else if (target.startsWith('packages/')) {
    // eslint-disable-next-line react-hooks/rules-of-hooks
    return useOrAddGenericPackage(error)
  }
}

const useOrAddGenericPackage = error => {
  const {target} = error
  const [packageName] = micromatch.capture('packages/*/**', target)
  const [pjsonFile, pjson] =
    t.findPackageJSON(target, [packageName, `@instructure/${packageName}`]) || []

  if (pjsonFile) {
    // eslint-disable-next-line react-hooks/rules-of-hooks
    return useExistingPackage(error, {pjsonFile, pjson})
  } else {
    return addGenericPackage(error, {packageName})
  }
}

const addGenericPackage = (error, {packageName}) => {
  let message = ''

  message += `<Hint>`
  message += `\n`
  message += t.wordWrap(
    `
    Package is missing a package.json, you should add one at
    packages/${packageName}/package.json with contents similar to:
  `,
    72
  )
  message += `\n`
  message += `
    {
      "name": "${packageName}",
      "version": "1.0.0"
    }`

  message += `\n`

  return message
}

const useOrAddCanvasPackage = error => {
  const {target} = error
  const [packageName] = micromatch.capture('ui/shared/*/**', target) || []
  const [pjsonFile, pjson] = t.findPackageJSON(target, [`@canvas/${packageName}`]) || []

  if (pjsonFile) {
    // eslint-disable-next-line react-hooks/rules-of-hooks
    return useExistingPackage(error, {pjsonFile, pjson})
  } else {
    return addCanvasPackage(error, {packageName})
  }
}

const addCanvasPackage = (error, {packageName}) => {
  let message = ''

  message += '<Hint>'
  message += `\n`
  message += t.wordWrap(
    `
    Canvas package is missing a package.json, you must add one at
    ui/shared/${packageName}/package.json with contents similar to:
  `.trim(),
    72
  )
  message += `\n`
  message += `
    {
      "name": "@canvas/${packageName}",
      "version": "1.0.0",
      "private": true
    }`
  message += `\n`

  return t.bracketize(message)
}

const useExistingPackage = ({request, target}, {pjsonFile, pjson}) => {
  const suggestion = [
    pjson.name, // e.g. @canvas/foo
    path.relative(
      // e.g. lib/index.js
      path.dirname(pjsonFile),
      t.withOrWithoutExtension(request, target) // or lib/index, w/o extension
    ),
  ].join('/')

  let message = ''

  message += `<Hint>`
  message += `\n`
  message += `Use a bare specifier:`
  message += `\n \n`
  message += `    ${suggestion}`
  message += `\n`

  return t.bracketize(message)
}
