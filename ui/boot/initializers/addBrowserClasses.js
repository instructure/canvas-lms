/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

if (!('INST' in window)) window.INST = {}

INST.browser = {}

INST.browser.webkit = isWebkit()

INST.browser.chrome = isChrome()

INST.browser.safari = isSafari()

INST.browser.ff = isFirefox(window.navigator.userAgent)

INST.browser.msie = isIE(window.navigator.userAgent)

INST.browser.touch = 'ontouchstart' in document

INST.browser['no-touch'] = !INST.browser.touch

const classesToAdd = Object.keys(INST.browser).filter(k => INST.browser[k])

document.body.classList.add(...classesToAdd)

export function isFirefox(ua) {
  return /Firefox/i.test(ua)
}

export function isIE(ua) {
  return ua.indexOf('MSIE') !== -1 || isIe11(ua)
}

export function isIe11(ua) {
  return ua.indexOf('Trident/7') !== -1
}

export function isOpera(ua) {
  return ua.indexOf('OPR/') !== -1 || ua.indexOf('Opera/') !== -1 || ua.indexOf('OPT/') !== -1
}

export function isWebkit() {
  return navigator.userAgent.indexOf('AppleWebKit') !== -1
}

export function isSafari() {
  return (
    !isFirefox(window.navigator.userAgent) &&
    isWebkit() &&
    escape(navigator.javaEnabled.toString()) !==
      'function%20javaEnabled%28%29%20%7B%20%5Bnative%20code%5D%20%7D'
  )
}

export function isChrome() {
  return (
    isWebkit() &&
    escape(navigator.javaEnabled.toString()) ===
      'function%20javaEnabled%28%29%20%7B%20%5Bnative%20code%5D%20%7D'
  )
}

export default INST
