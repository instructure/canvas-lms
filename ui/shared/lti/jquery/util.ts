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

let beforeUnloadHandler: null | ((e: BeforeUnloadEvent) => void) = null

export function setUnloadMessage(msg: string) {
  removeUnloadMessage()

  beforeUnloadHandler = function (e: BeforeUnloadEvent) {
    return (e.returnValue = msg || true)
  }
  window.addEventListener('beforeunload', beforeUnloadHandler)
}

export function removeUnloadMessage() {
  if (beforeUnloadHandler) {
    window.removeEventListener('beforeunload', beforeUnloadHandler)
    beforeUnloadHandler = null
  }
}

// disabling b/c eslint fails, saying 'MessageEventSource' is not defined, but it's
// defined in lib.dom.d.ts
export function findDomForWindow(
  // eslint-disable-next-line no-undef
  sourceWindow?: MessageEventSource | null,
  startDocument?: Document | null
) {
  startDocument = startDocument || document
  const iframes = Array.from(startDocument.getElementsByTagName('iframe'))
  const iframe = iframes.find(ifr => ifr.contentWindow === sourceWindow)
  return iframe || null
}

/**
 * Sometimes the iframe which is the window we're looking for is nested within an RCE iframe.
 * Those are same-origin, so we can look through those RCE iframes' documents
 * too for the window we're looking for.
 */
// eslint-disable-next-line no-undef
export function findDomForWindowInRCEIframe(sourceWindow?: MessageEventSource | null) {
  const iframes = document.querySelectorAll('.tox-tinymce iframe')
  for (let i = 0; i < iframes.length; i++) {
    const doc = (iframes[i] as HTMLIFrameElement).contentDocument
    if (doc) {
      const domElement = findDomForWindow(sourceWindow, doc)
      if (domElement) {
        return domElement
      }
    }
  }
  return null
}

// https://stackoverflow.com/a/70029241
// this can be removed and replace with `k in o`
//   when we upgrade to TS 4.9+
export function hasKey<K extends string, T extends object>(
  k: K,
  o: T
): o is T & Record<K, unknown> {
  return k in o
}

export function getKey(key: string, o: unknown): unknown {
  return typeof o === 'object' && o !== null && hasKey(key, o) ? o[key] : undefined
}

export function deleteKey(key: string, o: unknown): void {
  if (typeof o === 'object' && o !== null && hasKey(key, o)) {
    delete o[key]
  }
}
