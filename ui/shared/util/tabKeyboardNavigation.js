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

import $ from 'jquery'

/**
 * Sets up W3C ARIA-compliant keyboard navigation for tabs with automatic activation pattern.
 *
 * Implements the W3C ARIA Tabs Pattern (https://www.w3.org/WAI/ARIA/apg/patterns/tabs/)
 * with automatic activation, where arrow keys immediately navigate to and activate tabs.
 *
 * @param {jQuery} $tabContainer - The jQuery element containing the tab list (<ul>)
 * @param {Object} options - Configuration options
 * @param {boolean} options.handleHashNavigation - If true, handle hash-only hrefs (like #tab-1)
 *                                                  by activating tabs via jQuery UI instead of
 *                                                  navigating away. Default: false
 * @param {boolean} options.autoActivate - If true, arrow keys trigger navigation immediately.
 *                                          If false, arrow keys only move focus. Default: true
 * @param {boolean} options.useVoiceOverDelay - If true, use a 100ms delay before focusing to give
 *                                               screen readers time to process page state. Default: false
 *
 * @example
 * // Basic usage (cross-page navigation)
 * setupTabKeyboardNavigation($('#group_categories_tabs'))
 *
 * @example
 * // With same-page hash navigation
 * setupTabKeyboardNavigation($('#my-tabs'), { handleHashNavigation: true })
 *
 * @example
 * // With VoiceOver delay for cross-page navigation
 * setupTabKeyboardNavigation($('#my-tabs'), { useVoiceOverDelay: true })
 */
export function setupTabKeyboardNavigation($tabContainer, options = {}) {
  const {handleHashNavigation = false, autoActivate = true, useVoiceOverDelay = false} = options

  // Only select tab list items, not nested list items in tab panels (like groups)
  const $groupTabs = $tabContainer.find('> ul > li')
  const $groupTabLinks = $groupTabs.find('a')

  // Implement roving tabindex: only the active tab should be in tab order
  // All inactive tabs get tabindex="-1" so they're skipped during Tab/Shift+Tab
  const activeTab = $tabContainer.find('> ul > li.ui-tabs-active, > ul > li.ui-state-active')[0]
  $groupTabs.each(function () {
    if (this === activeTab) {
      $(this).attr('tabindex', '0')
    } else {
      $(this).attr('tabindex', '-1')
    }
  })

  $groupTabLinks.attr('tabindex', '-1')
  $groupTabLinks.attr('role', 'presentation')
  $groupTabLinks.attr('aria-hidden', 'true')

  // After setting up tabindex, focus the active tab
  // Always use setTimeout to ensure focus happens after all DOM updates and jQuery UI initialization
  const delay = useVoiceOverDelay ? 100 : 0
  setTimeout(() => {
    if (activeTab) {
      activeTab.focus()
    }
  }, delay)

  // Remove only our custom event handlers (if this is being called multiple times)
  // Don't use .off() without arguments as it removes ALL handlers including jQuery UI's
  $groupTabLinks.off('click keydown')
  $groupTabs.off('click keydown')

  const navigateToTab = $tab => {
    const $link = $tab.find('a')
    const href = $link.attr('href') || $link.data('original-href')
    if (!href) return

    // Check if this is a hash-only link (same page navigation)
    if (handleHashNavigation && href.startsWith('#')) {
      // For same-page hash navigation, activate the tab via jQuery UI tabs
      const tabIndex = $groupTabs.toArray().indexOf($tab[0])
      $tabContainer.tabs('option', 'active', tabIndex)
      // Ensure the tab has focus after activation
      requestAnimationFrame(() => {
        $tab[0].focus()
      })
    } else {
      // For external links, navigate via window.location
      window.location.href = href
    }
  }

  // Handle all keyboard and click events on the tab list items
  $groupTabs.on('click keydown', function (event) {
    const $currentTab = $(this)

    // Handle activation (click, Enter, Space) - navigate immediately
    if (event.type === 'click' || event.key === 'Enter' || event.key === ' ') {
      event.preventDefault()
      event.stopPropagation()
      navigateToTab($currentTab)
      return
    }

    // Handle arrow key navigation - AUTOMATIC ACTIVATION (move focus AND navigate)
    if (event.key === 'ArrowLeft' || event.key === 'ArrowRight') {
      event.preventDefault()
      event.stopPropagation()

      const $allTabs = $groupTabs.toArray()
      const currentIndex = $allTabs.indexOf(this)
      const nextIndex =
        event.key === 'ArrowRight'
          ? (currentIndex + 1) % $allTabs.length
          : (currentIndex - 1 + $allTabs.length) % $allTabs.length

      const $nextTab = $($allTabs[nextIndex])

      // Update roving tabindex: only the focused tab should be in tab order
      $groupTabs.attr('tabindex', '-1')
      $nextTab.attr('tabindex', '0')

      // Update aria-selected on all tabs
      $groupTabs.attr('aria-selected', 'false')
      $nextTab.attr('aria-selected', 'true')

      // Move focus to the next tab
      $nextTab[0].focus()

      // AUTOMATIC ACTIVATION: Navigate immediately when arrow key is pressed (if enabled)
      if (autoActivate) {
        navigateToTab($nextTab)
      }
    }

    // For other keys (like Tab), allow default behavior
  })
}
