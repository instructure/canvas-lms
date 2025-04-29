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

interface WaitForElementCallback {
  (element: Element): void
}

export const waitForElement = (
  selector: string,
  callback: WaitForElementCallback,
  interval = 100,
  timeout = 5000,
): void => {
  const start = Date.now()

  const timer = setInterval(() => {
    const element = document.querySelector(selector)
    const expired = Date.now() - start > timeout

    if (element || expired) {
      clearInterval(timer)
      if (element) {
        callback(element)
      } else {
        console.warn(`Timeout: Element "${selector}" not found.`)
      }
    }
  }, interval)
}

export function LoadTab(loadTabFunction: (tabId: string) => void) {
  waitForElement('div[role="tablist"]', settingsTabs => {
    const observer = new MutationObserver(mutations => {
      mutations.forEach(mutation => {
        if (mutation.type === 'attributes' && mutation.attributeName === 'aria-selected') {
          const target = mutation.target as HTMLElement
          if (target.getAttribute('aria-selected') === 'true') {
            const tabId = target.id
            if (tabId) loadTabFunction(tabId)
          }
        }
      })
    })

    const tabs = settingsTabs.querySelectorAll('[role="tab"]')
    tabs.forEach(tab => {
      observer.observe(tab, {
        attributes: true,
        attributeFilter: ['aria-selected'],
      })
    })

    const selectedTab = settingsTabs.querySelector<HTMLElement>(
      '[role="tab"][aria-selected="true"]',
    )
    if (selectedTab?.id) {
      loadTabFunction(selectedTab.id)
    }
  })
}
