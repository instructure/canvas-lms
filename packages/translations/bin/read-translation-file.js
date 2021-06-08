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

const fs = require('fs')
const path = require('path')

/**
 * This returns the contents of the translations for the given package and locale
 */
async function readTRanslationFile(packageName, locale) {
  const filePath = path.resolve(__dirname, `../lib/${packageName}/${locale}.json`)
  const jsonData = await fs.promises.readFile(filePath, {encoding: 'utf8'})
  // sanity check
  try {
    JSON.parse(jsonData)
  } catch (ex) {
    console.log(ex)
    throw new Error(`Failed parsing content from ${filePath}`)
  }
  return jsonData
}

module.exports = readTRanslationFile
