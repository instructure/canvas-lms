/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2015 - present Instructure, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
const path = require('path')
const postcss = require('postcss')

const loadConfig = require('@instructure/config-loader')

const generateComponentId = require('./generateComponentId')
const transformCSSRequire = require('./transform')
const generateScopedName = require('./generateScopedName')

const themeableConfig = loadConfig('themeable')
const noop = () => {}

if (themeableConfig && themeableConfig.generateScopedName) {
  console.warn(
    '[themeable-css-loader] Custom scoped CSS class names will be removed in 7.0. Please use the default themeable config.'
  )
}

module.exports = function (content, map, meta) {
  this.cacheable && this.cacheable()

  const loader = this
  const callback = loader.async()
  const filePath = loader.resourcePath
  // const relativePath = path.relative(process.cwd(), filePath)

  if (map) {
    if (typeof map === 'string') {
      // eslint-disable-next-line no-param-reassign
      map = JSON.stringify(map)
    }

    if (map.sources) {
      // eslint-disable-next-line no-param-reassign
      map.sources = map.sources.map((source) => source.replace(/\\/g, '/'))
      // eslint-disable-next-line no-param-reassign
      map.sourceRoot = ''
    }
  }

  // Reuse CSS AST (PostCSS AST e.g 'postcss-loader') to avoid reparsing
  let source = content
  const ast = meta && meta.ast
  if (ast && ast.type === 'postcss' && ast.root) {
    // eslint-disable-next-line no-param-reassign
    source = ast.root
  }

  const opts = {
    from: filePath,
    map: {
      prev: map,
      sourcesContent: true,
      inline: false, // inline sourcemaps will break the js templates
      annotation: false
    }
  }

  Promise.resolve()
    .then(() => {
      const componentId = generateComponentId(content)

      return postcss([
        require('@instructure/postcss-themeable-styles'),
        require('postcss-modules')({
          generateScopedName: generateScopedName.bind(
            null,
            () => componentId,
            themeableConfig
          ),
          getJSON: noop
        }),
        require('postcss-reporter')({ clearReportedMessages: true })
      ])
        .process(source, opts)
        .then((result) => {
          result.warnings().forEach((msg) => {
            loader.emitWarning(msg.toString())
          })

          const map = result.map ? result.map.toJSON() : null

          if (map) {
            map.file = path.resolve(map.file)
            map.sources = map.sources.map((src) => path.resolve(src))
          }

          if (!meta) {
            // eslint-disable-next-line no-param-reassign
            meta = {}
          }

          const ast = {
            type: 'postcss',
            version: result.processor.version,
            root: result.root
          }

          // eslint-disable-next-line no-param-reassign
          meta.ast = ast
          // eslint-disable-next-line no-param-reassign
          meta.messages = result.messages

          const locals = (result.messages || []).find(
            (message) => message.type === 'export' && message.exportTokens
          )

          callback(
            null,
            `exports = module.exports = ${transformCSSRequire(
              locals.exportTokens,
              result.css,
              componentId
            )}`,
            map,
            meta
          )

          return null
        })
    })
    .catch((err) => {
      if (err.file) {
        this.addDependency(err.file)
      }

      return err.name === 'CssSyntaxError'
        ? callback(new SyntaxError(err))
        : callback(err)
    })
}
