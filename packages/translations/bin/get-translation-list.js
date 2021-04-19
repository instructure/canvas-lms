/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
 * This returns an index of all the translation files for a given package
 */
async function getTranslationList(packageName) {
  const translationList = await fs.promises.readdir(
    path.resolve(__dirname, `../lib/${packageName}`)
  )
  return translationList
}

module.exports = getTranslationList
