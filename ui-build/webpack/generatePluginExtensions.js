/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

const fs = require('fs').promises
const path = require('path')

const pluginsDir = path.join(__dirname, '../../gems/plugins')
const outputPath = path.join(__dirname, '../../ui/shared/bundles/extensions.ts')

async function generateImports() {
  const imports = {}

  try {
    const pluginDirs = await fs.readdir(pluginsDir)

    for (const dir of pluginDirs) {
      const packagePath = path.join(pluginsDir, dir, 'package.json')

      try {
        // eslint-disable-next-line no-await-in-loop
        const packageJson = await fs.readFile(packagePath, 'utf8').catch(() => null)

        if (!packageJson) {
          continue
        }
        const packageObj = JSON.parse(packageJson)

        if (packageObj.canvas && packageObj.canvas['source-file-extensions']) {
          for (const [key, value] of Object.entries(packageObj.canvas['source-file-extensions'])) {
            imports[key] = `() =>\n    import(\n      '../../../gems/plugins/${path
              .join(dir, value)
              .replace(/\\/g, '/')}'\n    )`
          }
        }
      } catch (error) {
        console.error(`Error reading or parsing package.json in ${dir}: ${error}`)
      }
    }

    const importStatements = Object.entries(imports)
      .map(([key, value]) => `  '${key}': ${value}`)
      .join(',\n')

    const eslintDirectives =
      '/* eslint-disable import/extensions */\n/* eslint-disable notice/notice */\n\n'
    const outputContent = `${eslintDirectives}export default {\n${importStatements}${
      importStatements.length > 0 ? ',' : ''
    }\n}\n`
    await fs.writeFile(outputPath, outputContent, 'utf8')

    console.log('Generated imports:', outputPath)
  } catch (error) {
    console.error('An error occurred:', error)
  }
}

generateImports()
