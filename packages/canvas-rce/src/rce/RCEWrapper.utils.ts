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

import formatMessage from '../format-message'

// standard: string of tinymce menu commands
// e.g. 'instructure_links | inserttable instructure_media_embed | hr'
// custom: a string of tinymce menu commands
// returns: standard + custom with any duplicate commands removed from custom
export function mergeMenuItems(standard: string, custom?: string) {
  let c = custom?.trim?.()
  if (!c) return standard

  const s = new Set(standard.split(/[\s|]+/))
  // remove any duplicates
  const c_array = c.split(/\s+/).filter(m => !s.has(m))
  c = c_array
    .join(' ')
    .replace(/^\s*\|\s*/, '')
    .replace(/\s*\|\s*$/, '')
  return `${standard} | ${c}`
}

// standard: the incoming tinymce menu object
// custom: tinymce menu object to merge into standard
// returns: the merged result by mutating incoming standard arg.
// It will add commands to existing menus, or add a new menu
// if the custom one does not exist
export function mergeMenu(
  standard: Record<
    string,
    {
      items: string
    }
  >,
  custom: Record<
    string,
    {
      items: string
    }
  >,
) {
  if (!custom) return standard

  Object.keys(custom).forEach(k => {
    const curr_m = standard[k]
    if (curr_m) {
      curr_m.items = mergeMenuItems(curr_m.items, custom[k].items)
    } else {
      standard[k] = {...custom[k]}
    }
  })
  return standard
}

// standard: incoming tinymce toolbar array
// custom: tinymce toolbar array to merge into standard
// returns: the merged result by mutating the incoming standard arg.
// It will add commands to existing toolbars, or add a new toolbar
// if the custom one does not exist
export function mergeToolbar(
  standard: Array<{
    items: string[]
    name: string
  }>,
  custom: Array<{
    items: string[]
    name: string
  }>,
) {
  if (!custom) return standard
  // merge given toolbar data into the default toolbar
  custom.forEach(tb => {
    const curr_tb = standard.find(t => tb.name && formatMessage(tb.name) === t.name)
    if (curr_tb) {
      curr_tb.items.splice(curr_tb.items.length, 0, ...tb.items)
    } else {
      standard.push(tb)
    }
  })
  return standard
}

// standard: incoming array of plugin names
// custom: array of plugin names to merge
// exclusions: array of plugins to remove
// returns: the merged result, duplicates and exclusions removed
export function mergePlugins(standard: string[], custom: string[] = [], exclusions: string[] = []) {
  const union = new Set(standard)

  for (const c of custom) {
    union.add(c)
  }

  for (const e of exclusions) {
    union.delete(e)
  }

  return [...union]
}

export function focusToolbar(el: HTMLElement) {
  const $firstToolbarButton = el.querySelector('.tox-tbtn') as HTMLButtonElement
  if ($firstToolbarButton) {
    $firstToolbarButton.focus()
  }
}

export function focusFirstMenuButton(el: HTMLElement) {
  const $firstMenu = el.querySelector('.tox-mbtn') as HTMLButtonElement
  if ($firstMenu) {
    $firstMenu.focus()
  }
}

export function isElementWithinTable(node: Element | null) {
  let elem = node
  while (elem) {
    if (elem.tagName === 'TABLE' || elem.tagName === 'TD' || elem.tagName === 'TH') {
      return true
    }
    elem = elem.parentElement
  }
  return false
}

// plugins is an array of strings
// the convention is that plugins starting with '-',
// i.e. a hyphen, are to be disabled in the RCE instance
export function parsePluginsToExclude(plugins: string[]) {
  return plugins
    .filter(plugin => plugin.length > 0 && plugin[0] === '-')
    .map(pluginToIgnore => pluginToIgnore.slice(1))
}

// if a placeholder image shows up in autosaved content, we have to remove it
// because the data url gets converted to a blob, which is not valid when restored.
// besides, the placeholder is intended to be temporary while the file
// is being uploaded
export function patchAutosavedContent(content: string, asText: boolean = false) {
  const temp = document.createElement('div')
  temp.innerHTML = content
  temp.querySelectorAll('[data-placeholder-for]').forEach(placeholder => {
    // @ts-expect-error
    placeholder.parentElement.removeChild(placeholder)
  })
  if (asText) return temp.textContent
  return temp.innerHTML
}
