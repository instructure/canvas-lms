/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import axios from '@canvas/axios'

const I18n = createI18nScope('Navigation')

export type ExternalTool = {
  href: string | null
  imgSrc?: string | null
  label: string
  svgPath?: string | null
}

export const getExternalApps = async (): Promise<ExternalTool[]> => {
  const {data: tools} = await axios.get(
    `/api/v1/accounts/${window.ENV.ACCOUNT_ID}/lti_apps/launch_definitions?per_page=50&placements[]=global_navigation&only_visible=true`,
  )
  if (!Array.isArray(tools)) return []
  return tools
    .map((tool: any) => {
      const globalNavigation = tool.placements?.global_navigation
      if (!globalNavigation?.title) {
        return null
      }
      return {
        href: globalNavigation.html_url,
        label: globalNavigation.title,
        imgSrc: globalNavigation.icon_url || null,
        svgPath: globalNavigation.icon_svg_path_64 || null,
      } as ExternalTool
    })
    .filter((app): app is ExternalTool => app !== null)
}

export function getExternalTools(): ExternalTool[] {
  return Array.from(document.querySelectorAll('.globalNavExternalTool')).map(el => {
    const svg = el.querySelector('svg')
    return {
      href: el.querySelector('a')?.getAttribute('href') || null,
      label: (el.querySelector('.menu-item__text') as HTMLDivElement)?.innerText || '',
      svgPath: svg?.innerHTML || null,
      imgSrc: svg
        ? null
        : (el.querySelector('img') as HTMLImageElement)?.getAttribute('src') || null,
    }
  })
}

export type ActiveTray =
  | 'accounts'
  | 'calendar'
  | 'conversations'
  | 'courses'
  | 'dashboard'
  | 'groups'
  | 'help'
  | 'history'
  | 'profile'

const ACTIVE_CLASS = 'ic-app-header__menu-list-item--active'
export function setActiveClass(activeItem: string | null) {
  const activeElement = document.querySelector(`.${ACTIVE_CLASS}`)
  if (activeElement) {
    activeElement.classList.remove(ACTIVE_CLASS)
    activeElement.removeAttribute('aria-current')
  }

  if (activeItem) {
    const listItem = document.querySelector(`#global_nav_${activeItem}_link`)?.closest('li')
    if (listItem) {
      listItem.classList.add(ACTIVE_CLASS)
      listItem.setAttribute('aria-current', 'page')
    }
  }
}

const EXTERNAL_TOOLS_REGEX = /^\/accounts\/[^\/]*\/(external_tools)/
const ACTIVE_ROUTE_REGEX =
  /^\/(courses|groups|accounts|grades|calendar|conversations|profile)|^#history/
export function getActiveItem(): ActiveTray | '' {
  const path = window.location.pathname
  const toolId = window.location.search.split('toolId=')
  const matchData = path.match(EXTERNAL_TOOLS_REGEX) || path.match(ACTIVE_ROUTE_REGEX)
  return (toolId && (toolId[1] as ActiveTray)) ?? (matchData && (matchData[1] as ActiveTray)) ?? ''
}

export function getTrayLabel(type: string | null) {
  switch (type) {
    case 'courses':
      return I18n.t('Courses tray')
    case 'groups':
      return I18n.t('Groups tray')
    case 'accounts':
      return I18n.t('Admin tray')
    case 'profile':
      return I18n.t('Profile tray')
    case 'help':
      return I18n.t('%{title} tray', {title: window.ENV.help_link_name})
    case 'history':
      return I18n.t('Recent History tray')
    default:
      return I18n.t('Global navigation tray')
  }
}

// give the trays that slide out from the the nav bar
// a place to mount. It has to be outside the <div id=application>
// to aria-hide everything but the tray when open.
let portal: HTMLDivElement | undefined
export function getTrayPortal() {
  if (!portal) {
    portal = document.createElement('div')
    portal.id = 'nav-tray-portal'
    // the <header> has z-index: 100. This has to be behind it,
    portal.setAttribute('style', 'position: relative; z-index: 99;')
    document.body.appendChild(portal)
  }
  return portal
}

export function sideNavReducer(state: any, action: {type: any; payload?: any}) {
  switch (action.type) {
    case 'SET_ACTIVE_TRAY':
      return {
        ...state,
        activeTray: action.payload,
        isTrayOpen: !!action.payload,
        previousSelectedNavItem: action.payload
          ? state.selectedNavItem
          : state.previousSelectedNavItem,
      }
    case 'SET_SELECTED_NAV_ITEM':
      return {
        ...state,
        selectedNavItem: action.payload,
      }
    case 'SET_IS_TRAY_OPEN':
      return {
        ...state,
        isTrayOpen: action.payload,
      }
    case 'RESET_ACTIVE_TRAY':
      return {
        ...state,
        activeTray: null,
        selectedNavItem: state.previousSelectedNavItem,
      }
    default:
      return state
  }
}

export interface ProcessedTool {
  href: string | null
  label: string
  svgPath?: string | null
  toolId: string
  toolImg?: string | null
}

export function filterAndProcessTools(tools: ExternalTool[] | null | undefined): ProcessedTool[] {
  if (tools == null) {
    return []
  }
  return tools
    .filter(tool => tool.label?.trim())
    .map(tool => ({
      href: tool.href || null,
      label: tool.label,
      svgPath: tool.svgPath || null,
      toolId: tool.label.toLowerCase().replaceAll(' ', '-'),
      toolImg: tool.imgSrc || null,
    }))
}
