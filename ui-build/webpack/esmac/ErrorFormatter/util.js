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

const path = require('path')
const wrapAnsi = require('wrap-ansi')
const findUp = require('find-up')

exports.bracketize = message => {
  const lines = message.split('\n')

  return lines
    .slice(0, 1)
    .concat([':'])
    .concat(lines.slice(1).map(line => `|  ${line}`))
    .concat([':'])
    .join('\n')
}

// webpack's stack trace is padded by 1 space, it's easier on the eyes to align
// the message to it
exports.alignWithWebpackStackTrace = message =>
  message
    .split('\n')
    .map(x => ` ${x}`)
    .join('\n')

exports.wordWrap = (paragraph, columns = 72) =>
  wrapAnsi(paragraph.trim().replace(/\s{2,}/g, ' '), columns)

// node's path#relative() function doesn't show a leading ./, which is confusing
// if you're trying to communicate a path should be relative because it
// otherwise looks bare
exports.withLeadingDotSlash = x => (x.startsWith('.') ? x : `./${x}`)

// if the original file has an extension, keep it in the suggested version,
// otherwise omit it (suggested is assumed to always have an extension!)
exports.withOrWithoutExtension = (original, suggested) => {
  const originalExt = path.extname(original)

  if (originalExt.length) {
    return suggested
  }

  const suggestedExt = path.extname(suggested)

  if (suggestedExt.length) {
    return suggested.slice(0, -suggestedExt.length)
  } else {
    return suggested
  }
}

const findPackageJSON = (file, names) => {
  const pjsonFile = findUp.sync('package.json', {cwd: path.dirname(file)})

  if (!pjsonFile) {
    return null
  }

  // eslint-disable-next-line import/no-dynamic-require
  const pjson = require(pjsonFile)

  if (pjson.name && names.includes(pjson.name)) {
    return [pjsonFile, pjson]
  } else {
    return findPackageJSON(path.dirname(pjsonFile), names)
  }
}

exports.findPackageJSON = findPackageJSON
