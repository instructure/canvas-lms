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

// feature detect for webp support
let supportsWebp = false
const testImg = new Image()
testImg.onload = () => (supportsWebp = testImg.width === 1)
testImg.src = 'data:image/webp;base64,UklGRiQAAABXRUJQVlA4IBgAAAAwAQCdASoBAAEAAwA0JaQAA3AA/vuUAAA='

const dpiMultiplier =
  window.devicePixelRatio <= 1 /* device does not have a HighDPI screen */ ||
  // @ts-expect-error
  navigator?.connection?.downlink < 5 /* slow (less than 5mbps) connection */ ||
  // @ts-expect-error
  navigator?.connection?.saveData /* user has asked to save bandwidth */
    ? 1
    : 2

/**
 * returns a url with proper query string parameters to get an image from instFS
 * resized to certain dimensions and possibly formatted as wepb  (if the browser supports it)
 * so it is smaller to download than the original.
 * @param {string} url - the url of an image served by InstFS
 * @param {object} geometry - the desired dimensions the image will be displayed in
 * @param {number} geometry.x - width
 * @param {number} geometry.y - height
 * @returns <String> url with query string parameters added
 */
export default function instFSOptimizedImageUrl(
  url: string,
  {
    x,
    y,
  }: {
    x: number
    y: number
  }
) {
  if (url && url.startsWith('https://inst-fs-')) {
    url += (url.includes('?') ? '&' : '?') + `geometry=${x * dpiMultiplier}x${y * dpiMultiplier}`
    if (supportsWebp) url += '&format=webp'
  }
  return url
}
