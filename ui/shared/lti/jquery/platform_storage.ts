// @ts-nocheck
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

const STORAGE_CHAR_LIMIT = 4096 // IMS minimum storage limit is 4096 bytes so 4096 chars is more than enough
const STORAGE_KEY_LIMIT = 500

export const limits = {}

export const createLimit = tool_id => {
  if (!limits[tool_id]) {
    limits[tool_id] = {keyCount: 0, charCount: 0}
  }
}

export const getLimit = tool_id => {
  createLimit(tool_id)
  return limits[tool_id]
}

export const clearLimit = (tool_id: string) => {
  delete limits[tool_id]
}

export const addToLimit = (tool_id: string, key: string, value: string) => {
  createLimit(tool_id)
  const length = key.length + value.length

  if (limits[tool_id].keyCount >= STORAGE_KEY_LIMIT) {
    const e: Error & {code?: string} = new Error('Reached key limit for tool')
    e.code = 'storage_exhaustion'
    throw e
  }

  if (limits[tool_id].charCount + length > STORAGE_CHAR_LIMIT) {
    const e: Error & {code?: string} = new Error('Reached byte limit for tool')
    e.code = 'storage_exhaustion'
    throw e
  }

  limits[tool_id].keyCount++
  limits[tool_id].charCount += length
}

export const removeFromLimit = (tool_id: string, key: string, value: string) => {
  limits[tool_id].keyCount--
  limits[tool_id].charCount -= key.length + value.length

  if (limits[tool_id].keyCount < 0) {
    limits[tool_id].keyCount = 0
  }
  if (limits[tool_id].charCount < 0) {
    limits[tool_id].charCount = 0
  }
}

export const getKey = (tool_id: string, key: string) => `lti|platform_storage|${tool_id}|${key}`

export const putData = (tool_id: string, key: string, value: string) => {
  addToLimit(tool_id, key, value)
  window.localStorage.setItem(getKey(tool_id, key), value)
}

export const getData = (tool_id: string, key: string) =>
  window.localStorage.getItem(getKey(tool_id, key))

export const clearData = (tool_id: string, key: string) => {
  const value = getData(tool_id, key)
  if (value) {
    removeFromLimit(tool_id, key, value)
    window.localStorage.removeItem(getKey(tool_id, key))
  }
}
