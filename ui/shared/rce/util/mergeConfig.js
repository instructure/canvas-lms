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

/**
 * Merges configuration arrays that are in both defaultOptions and
 * customOptions
 *
 * @private
 *
 * @param {Array} properties An array of configuration keys that should be considered for merging.
 * @param {Object} defaultOptions The default configuration
 * @param {Object} customOptions The custom configuration that should override the defaultOptions
 *
 * @returns {Object} A new object with merged configuration arrays
 */
export default function mergeConfig(optionsToMerge, defaultOptions, customOptions) {
  const retVal = {...customOptions}

  optionsToMerge.forEach(c => {
    const defaultVal = defaultOptions[c]
    const customVal = customOptions[c]

    // Merge the two configuration values if they are both arrays
    if (Array.isArray(defaultVal) && Array.isArray(customVal)) {
      retVal[c] = [...new Set(defaultVal.concat(customVal))]
    }
  })

  return retVal
}
