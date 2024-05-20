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

import {IconExternalLinkLine} from '@instructure/ui-icons/es/svg'
import {getTld} from './instructure_helper'
import formatMessage from '../format-message'

const IconExternalLinkSVG = IconExternalLinkLine?.src || '<svg></svg>'

export function makeExternalLinkIcon(forLink) {
  const dir = (forLink && window.getComputedStyle(forLink).direction) || 'ltr'
  const $icon = document.createElement('span')
  $icon.setAttribute('class', 'external_link_icon')
  const style = `margin-inline-start: 5px; display: inline-block; text-indent: initial; ${
    dir === 'rtl' ? 'transform:scale(-1, 1)' : ''
  }`
  $icon.setAttribute('style', style)
  $icon.setAttribute('role', 'presentation')
  $icon.innerHTML = IconExternalLinkSVG
  $icon.firstChild.setAttribute(
    'style',
    'width:1em; height:1em; vertical-align:middle; fill:currentColor'
  )

  const srspan = document.createElement('span')
  srspan.setAttribute('class', 'screenreader-only')
  srspan.textContent = formatMessage('Links to an external site.')
  $icon.appendChild(srspan)
  return $icon
}

export function makeAllExternalLinksExternalLinks() {
  // in 100ms (to give time for everything else to load), find all the external links and add give them
  // the external link look and behavior (force them to open in a new tab)
  setTimeout(function () {
    const content = document.getElementById('content')
    if (!content) return
    const tld = getTld(window.location.hostname)
    const links = content.querySelectorAll(`a[href*="//"]:not([href*="${tld}"])`) // technique for finding "external" links copied from https://davidwalsh.name/external-links-css
    for (let i = 0; i < links.length; i++) {
      const $link = links[i]
      // don't mess with the ones that were already processed in enhanceUserContent
      if ($link.classList.contains('external')) continue
      if ($link.matches('.open_in_a_new_tab')) continue
      if ($link.querySelectorAll('img').length > 0) continue
      if ($link.matches('.not_external')) continue
      if ($link.matches('.exclude_external_icon')) continue
      // we have some pre-instui buttons that are styled links
      if ($link.classList.contains('btn')) continue
      const $linkToReplace = $link
      if ($linkToReplace) {
        const $linkIndicator = makeExternalLinkIcon()
        $linkToReplace.classList.add('external')
        $linkToReplace.querySelectorAll('span.ui-icon-extlink').forEach(c => c.remove)
        $linkToReplace.setAttribute('target', '_blank')
        $linkToReplace.setAttribute('rel', 'noreferrer noopener')
        const $linkSpan = document.createElement('span')
        const $linkText = $linkToReplace.innerHTML
        $linkSpan.innerHTML = $linkText
        while ($linkToReplace.firstChild) $linkToReplace.removeChild($linkToReplace.firstChild)
        $linkToReplace.appendChild($linkSpan)
        $linkToReplace.appendChild($linkIndicator)
      }
    }
  }, 100)
}
