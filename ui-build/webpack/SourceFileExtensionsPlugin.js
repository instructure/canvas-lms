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

const crypto = require('crypto')
const fs = require('fs')
const mkdirp = require('mkdirp')
const path = require('path')

/**
 * Extend source files with code found in Canvas plugins (not Webpack plugins).
 *
 *   Wraps modules with custom code
 *
 * To extend a source file, a plugin must provide a mapping inside its package
 * manifest from that file, relative to canvas-lms root, to the extension file
 * relative to the plugin root:
 *
 *     // file: gems/plugins/my_canvas_plugin/package.json
 *     {
 *       "name": "my_canvas_plugin",
 *       "canvas": {
 *         "source-file-extensions": {
 *           "path/to/source.js": "path/to/extension.js"
 *            ^^^^^^^^^^^^^^^^^    ^^^^^^^^^^^^^^^^^^^^
 *            from canvas-lms/     from gems/plugins/my_canvas_plugin/
 *         }
 *       }
 *     }
 *
 * If either file does not exist, the build will be aborted. You may specify
 * an array of extension files for a single source file.
 *
 * The extension file must export a function that receives and returns a single
 * argument -- the source file's default export:
 *
 *     // file: gems/plugins/my_canvas_plugin/app/js/extension-for-a.js
 *     export default a => {
 *       // do something with a and return it
 *       return a
 *     }
 *
 * Following that example, the generated code will be equivalent to:
 *
 *     import a from 'path/to/a.js'
 *     import ext1 from 'gems/plugins/my_canvas_plugin/app/js/extension-for-a.js'
 *
 *     export default ext1(a)
 *
 * Please be civil with extensions.
 */
class SourceFileExtensionsPlugin {
  // @param context: <Path>
  //        Root directory for the application (normally: /path/to/canvas-lms)
  //
  // @param include: <Array.<Path>>
  //        Paths to package.json manifests to scan for extensions.
  //
  // @param tmpDir: <Path>
  //        Directory that will hold the generated extended files. This is
  //        intended for internal use by the bundler and should not be served.
  constructor({context, include, tmpDir}) {
    this.context = context
    this.include = include
    this.tmpDir = tmpDir
  }

  apply(compiler) {
    const [extensions, extensionErrors] = this.scanManifestsForExtensions()
    const extended = this.generateAndPersistExtendedModules(extensions)

    compiler.hooks.compilation.tap('SourceFileExtensionsPlugin', compilation => {
      for (const error of extensionErrors) {
        compilation.errors.push(error)
      }
    })

    compiler.resolverFactory.hooks.resolver
      .for('normal')
      .tap('SourceFileExtensionsPlugin', resolver => {
        resolver.hooks.result.tap('SourceFileExtensionsPlugin', request => {
          if (extended[request.path] && request.context.issuer !== extended[request.path]) {
            request.path = extended[request.path]
          }
        })
      })
  }

  scanManifestsForExtensions() {
    const {context, include} = this
    const extensions = {}
    const errors = []

    for (const file of include) {
      // eslint-disable-next-line import/no-dynamic-require
      const manifest = require(file)
      const mapping = (manifest.canvas && manifest.canvas['source-file-extensions']) || {}

      for (const [fileInCanvas, filesInPlugin] of Object.entries(mapping)) {
        const sourceFile = path.resolve(context, fileInCanvas)

        if (fs.existsSync(sourceFile)) {
          // multiple files can extend the same source
          for (const fileInPlugin of [].concat(filesInPlugin)) {
            extensions[sourceFile] = extensions[sourceFile] || []
            extensions[sourceFile].push(path.join(path.dirname(file), fileInPlugin))
          }
        } else {
          errors.push(
            new Error(
              `${path.relative(context, file)} - file marked for extension does not exist:\n\n` +
                `    ${fileInCanvas}\n\n` +
                `(by SourceFileExtensionsPlugin)`
            )
          )
        }
      }
    }

    return [extensions, errors]
  }

  generateAndPersistExtendedModules(extensions) {
    const {context, tmpDir} = this
    const extended = {}

    mkdirp.sync(tmpDir)

    for (const [sourceFile, extensionFiles] of Object.entries(extensions)) {
      const fileInCanvas = path.relative(context, sourceFile)
      const extendedFile = path.join(tmpDir, md5(fileInCanvas) + '.js')
      const extendedModule = generateExtendedModule({
        context: tmpDir,
        sourceFile,
        extensionFiles,
      })

      fs.writeFileSync(extendedFile, extendedModule, 'utf8')

      extended[sourceFile] = extendedFile
    }

    return extended
  }
}

const md5 = string => crypto.createHash('md5').update(string).digest('hex')

const generateExtendedModule = ({context, extensionFiles, sourceFile}) => {
  const relative = file => path.relative(context, file)
  const imports = [`import orig from "${relative(sourceFile)}";`]
  const pipeline = []

  for (const [i, file] of extensionFiles.entries()) {
    imports.push(`import ext${i} from "${relative(file)}";`)
    pipeline.push(`ext${i}`)
  }

  return (
    `${imports.join('\n')}\n` +
    `export default ${pipeline.reduce((buf, fn) => `${fn}(${buf})`, 'orig')};` +
    `\n`
  )
}

module.exports = SourceFileExtensionsPlugin
