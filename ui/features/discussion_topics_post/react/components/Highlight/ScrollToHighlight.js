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

async function scrollToHighlight(element, _window = window) {
  const scrollableParent = (() => {
    const drawerLayoutContent = _window.document.getElementById('drawer-layout-content')
    if (drawerLayoutContent) {
      return {
        get scrollY() { return drawerLayoutContent.scrollTop },
        scrollToY(y) { drawerLayoutContent.scrollTo(drawerLayoutContent.scrollLeft, y) },
      }
    }
    return {
      get scrollY() { return _window.scrollY },
      scrollToY(y) { _window.scrollTo(_window.scrollX, y) },
    }
  })()
  const EXPIRE_AFTER_MS = 10_000
  const SCROLL_MAGNITUDE_MULTIPLIER = 2.6
  const SCROLL_MAGNITUDE_MIN = 600
  const SCROLL_MARGIN_TOP = 64
  const WAIT_FOR_ADDITIONAL_SCROLL_SECONDS = 3
  const activeElementAtStart = _window.document.activeElement
  if (!element) return 'NO_ELEMENT_TO_SCROLL_TO'
  const startTime = _window.Date.now()

  let shouldAbortDueToInteraction = false
  const abortViaMouse = () => shouldAbortDueToInteraction = true
  const abortViaKeyboard = event => {
    if (["Home", "End", "PageUp", "PageDown", "ArrowUp", "ArrowDown"].includes(event.key)) {
      shouldAbortDueToInteraction = true
    }
  }
  _window.addEventListener('wheel', abortViaMouse)
  _window.addEventListener('mousedown', abortViaMouse)
  _window.addEventListener('keydown', abortViaKeyboard)

  let elementPreviousOffsetTop = element.offsetTop
  let waitForAdditionalScrollSecondsLeft = WAIT_FOR_ADDITIONAL_SCROLL_SECONDS
  try {
    while (true) {
      const now = _window.Date.now()
      await new Promise(resolve => _window.requestAnimationFrame(resolve))
      const deltaTimeSeconds = (_window.Date.now() - now) / 1000
      const yDifference = element.offsetTop - SCROLL_MARGIN_TOP - scrollableParent.scrollY
      const magnitude = Math.max(
        Math.abs(yDifference) * SCROLL_MAGNITUDE_MULTIPLIER,
        SCROLL_MAGNITUDE_MIN) * deltaTimeSeconds * Math.sign(yDifference)
      const targetY = yDifference >= 0
        ? Math.min(element.offsetTop - SCROLL_MARGIN_TOP, scrollableParent.scrollY + magnitude)
        : Math.max(element.offsetTop - SCROLL_MARGIN_TOP, scrollableParent.scrollY + magnitude)
      scrollableParent.scrollToY(targetY)
      if (elementPreviousOffsetTop === element.offsetTop && targetY === scrollableParent.scrollY) {
        waitForAdditionalScrollSecondsLeft -= deltaTimeSeconds
      } else {
        elementPreviousOffsetTop = element.offsetTop
        waitForAdditionalScrollSecondsLeft = WAIT_FOR_ADDITIONAL_SCROLL_SECONDS
      }
      if (
        // Abort to give scroll control back to the user if:
        waitForAdditionalScrollSecondsLeft <= 0 || // The element has not moved and we didn't scroll in WAIT_FOR_ADDITIONAL_SCROLL_SECONDS. Abort.
        _window.Date.now() - startTime > EXPIRE_AFTER_MS || // We've been scrolling for too long. Abort.
        _window.document.activeElement !== activeElementAtStart || // The user interacted in a way that would change which element is focused (ex.: TAB key). Abort.
        shouldAbortDueToInteraction // The user scrolled via mouse or touchpad or "swiping", or clicked (maybe on the scroll bar?), or scrolled via keyboard. Abort.
      ) break
    }
  } finally {
    _window.removeEventListener('wheel', abortViaMouse)
    _window.removeEventListener('mousedown', abortViaMouse)
    _window.removeEventListener('keydown', abortViaKeyboard)
  }
  return 'SCROLL_ABORTED'
}

export { scrollToHighlight }
