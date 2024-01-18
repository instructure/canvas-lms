/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

const XSSLint = require('xsslint')
const Linter = require('xsslint/linter')
const globby = require('gglobby')
const fs = require('fs')
const glob = require('glob')
const babylon = require('@babel/parser')

XSSLint.configure({
  'xssable.receiver.whitelist': ['formData'],
  'jqueryObject.identifier': [/^\$/],
  'jqueryObject.property': [/^\$/],
  'safeString.identifier': [/(_html|Html|View|Template)$/, 'html', 'id'],
  'safeString.function': ['h', 'raw', 'htmlEscape', 'template', /(Template|View|Dialog)$/],
  'safeString.property': ['template', 'id', 'height', 'width', /_id$/],
  'safeString.method': [
    'escapeContent',
    'template',
    /(Template|Html)$/,
    'toISOString',
    'friendlyDatetime',
    /^(date|(date)?time)String$/,
  ],
})

// treat I18n.t calls w/ wrappers as html-safe, since they are
const origIsSafeString = Linter.prototype.isSafeString
Linter.prototype.isSafeString = function (node) {
  const result = origIsSafeString.call(this, node)
  if (result) return result

  if (node.type !== 'CallExpression') return false

  const {type, object, property} = node.callee
  if (type !== 'MemberExpression') return false
  if (object.type !== 'Identifier' || object.name !== 'I18n') return false
  if (property.type !== 'Identifier' || (property.name !== 't' && property.name !== 'translate'))
    return false

  const lastArg = node.arguments[node.arguments.length - 1]
  if (lastArg.type !== 'ObjectExpression') return false

  const hasWrapper = lastArg.properties.some(
    prop => prop.key.name === 'wrapper' || prop.key.name === 'wrappers'
  )
  return hasWrapper
}

function getFilesAndDirs(root, files = [], dirs = []) {
  root = root === '.' ? '' : `${root}/`

  const entries = fs.readdirSync(root || '.')
  entries.forEach(entry => {
    const stats = fs.lstatSync(root + entry)
    if (stats.isSymbolicLink()) {
      // do nothing
    } else if (stats.isDirectory()) {
      dirs.push(`${root + entry}/`)
      getFilesAndDirs(root + entry, files, dirs)
    } else {
      files.push(root + entry)
    }
  })

  return [files, dirs]
}

function methodDescription(method) {
  switch (method) {
    case '+':
      return 'HTML string concatenation'
    case '`':
      return 'HTML template literal'
    default:
      return `argument to \`${method}\``
  }
}

const cwd = process.cwd()
let warningCount = 0

const allPaths = [
  {
    paths: ['ui'].concat(glob.sync('gems/plugins/*/app/jsx')),
    glob: '*.js',
  },
  {
    paths: glob.sync('gems/plugins/*/public/javascripts'),
    defaultIgnores: ['/compiled', '/jst', '/vendor'],
    glob: '*.js',
  },
]

allPaths.forEach(({paths, glob, defaultIgnores = ['**/__tests__/**/*.js'], transform}) => {
  paths.forEach(path => {
    process.chdir(path)
    const ignores = defaultIgnores.concat(
      fs.existsSync('.xssignore')
        ? fs
            .readFileSync('.xssignore')
            .toString()
            .trim()
            .split(/\r?\n|\r/)
        : []
    )
    let candidates = getFilesAndDirs('.')
    candidates = {files: candidates[0], dirs: candidates[1]}

    const files = globby.select([glob], candidates).reject(ignores).files

    console.log(`Checking ${path} (${files.length} files) for potential XSS vulnerabilities...`)

    files.forEach(file => {
      let source = fs.readFileSync(file).toString()
      if (transform) source = transform(source)
      source = babylon.parse(source, {
        plugins: [
          'jsx',
          'classProperties',
          'objectRestSpread',
          'dynamicImport',
          'optionalChaining',
        ],
        sourceType: 'module',
      })
      const warnings = XSSLint.run({source})
      warningCount += warnings.length
      warnings.forEach(({line, method}) => {
        console.error(`${path}/${file}:${line}: possibly XSS-able ${methodDescription(method)}`)
      })
    })

    process.chdir(cwd)
  })
})

if (warningCount) {
  console.error(`\u{1b}[31mFound ${warningCount} potential vulnerabilities\u{1b}[0m`)
  process.exit(1)
} else {
  console.log('No problems found!')
}
