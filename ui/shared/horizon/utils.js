/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

export const HORIZON_PARAMS = {
  content_only: 'true',
  instui_theme: 'career',
  force_classic: 'true',
}

/**
 * Helper function to append parameters to a URL
 * @param {string} baseUrl - The base URL to append parameters to
 * @param {Object} params - Parameters to append
 * @returns {string} The URL with parameters appended
 */
function appendParamsToUrl(baseUrl, params) {
  if (Object.keys(params).length === 0) {
    return baseUrl
  }

  const url = new URL(baseUrl, window.location.origin)
  Object.entries(params).forEach(([key, value]) => {
    url.searchParams.set(key, value)
  })

  return url.toString()
}

/**
 * Builds a URL with horizon parameters appended
 * @param {string} baseUrl - The base URL to append parameters to
 * @param {Object} additionalParams - Additional parameters to include
 * @returns {string} The URL with horizon parameters
 */
export function buildHorizonUrl(baseUrl, additionalParams = {}) {
  const allParams = {...HORIZON_PARAMS, ...additionalParams}
  return appendParamsToUrl(baseUrl, allParams)
}

/**
 * Redirects to a URL with horizon parameters automatically appended if needed
 * @param {string} url - The URL to redirect to
 * @param {Object} additionalParams - Additional parameters to include
 */
export function redirectWithHorizonParams(url, additionalParams = {}) {
  if (ENV.horizon_course) {
    window.location.href = buildHorizonUrl(url, additionalParams)
  } else {
    window.location.href = url
  }
}

/**
 * Gets a URL with horizon parameters appended if in horizon course
 * @param {string} url - The URL to process
 * @param {Object} additionalParams - Additional parameters to include
 * @returns {string} The URL with or without horizon parameters based on context
 */
export function getUrlWithHorizonParams(url, additionalParams = {}) {
  if (ENV.horizon_course) {
    return buildHorizonUrl(url, additionalParams)
  }
  return appendParamsToUrl(url, additionalParams)
}
