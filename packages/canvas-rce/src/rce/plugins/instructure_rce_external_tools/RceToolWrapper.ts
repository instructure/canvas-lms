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

import {ExternalToolsEnv, RceLtiToolInfo} from './ExternalToolsEnv'
import {openToolDialogFor} from './dialog-helper'
import {simpleCache} from '../../../util/simpleCache'
import {instUiIconsArray} from '../../../util/instui-icon-helper'

// @ts-ignore
import {IconLtiSolid} from '@instructure/ui-icons/es/svg'

export interface ExternalToolMenuItem {
  type: 'menuitem'
  text: string
  icon?: string
  onAction: () => void
}

interface ExternalToolData {
  id: string;
  always_on?: boolean | null;
  favorite?: boolean | null;
}

export function externalToolsForToolbar<T extends ExternalToolData>(tools: T[]): T[] {
  const favorited = tools.filter(it => it.favorite).slice(0, 2) || []
  // There's no limit to always on apps, but in practice there shouldn't be more than 2 as well.
  const alwaysOn = tools.filter(it => it.always_on) || []

  const set = new Map<string, T>()

  // Remove possible overlaps between favorited and alwaysOn, otherwise
  // we'd have duplicate buttons in the toolbar.
  for (const toolInfo of favorited.concat(alwaysOn)) {
    set.set(toolInfo.id, toolInfo)
  }

  return Array.from(set.values()).sort((a, b) => {
    if (a.always_on && !b.always_on) {
      return -1;
    } else if (!a.always_on && b.always_on) {
      return 1;
    } else {
      // This *should* always be a string, but there might be cases where it isn't,
      // especially when this method is used outside of TypeScript files.
      return a.id.toString().localeCompare(b.id.toString(), undefined, {numeric: true})
    }
  })
}

/**
 * Helper class for the connection between an external tool registration and a particular TinyMCE instance.
 */
export class RceToolWrapper {
  static forEditorEnv(
    env: ExternalToolsEnv,
    toolConfigs = env.availableRceLtiTools,
    mruIds = loadMruToolIds()
  ): RceToolWrapper[] {
    return toolConfigs.map(it => new RceToolWrapper(env, it, mruIds))
  }

  public readonly iconId: string | null | undefined

  public isMruTool: boolean

  get editor() {
    return this.env.editor
  }

  constructor(
    public readonly env: ExternalToolsEnv,
    private readonly toolInfo: RceLtiToolInfo,
    mruToolIds: string[]
  ) {
    this.iconId = registerToolIcon(env, toolInfo)
    this.isMruTool = mruToolIds.includes(String(toolInfo.id))
  }

  get id(): string {
    return String(this.toolInfo.id)
  }

  get title(): string {
    return this.toolInfo.name ?? `Unknown tool (${String(this.toolInfo.id)})`
  }

  get description(): string | null | undefined {
    return this.toolInfo.description
  }

  get favorite(): boolean {
    return this.toolInfo.favorite ?? false
  }

  get image(): string | null | undefined {
    return parseIconValueFor(this.toolInfo)?.iconUrl
  }

  get width(): number | null | undefined {
    return this.toolInfo.width
  }

  get height(): number | null | undefined {
    return this.toolInfo.height
  }

  get use_tray(): boolean | null | undefined {
    return this.toolInfo.use_tray
  }

  get always_on() {
    return this.toolInfo.always_on
  }

  asToolbarButton() {
    return {
      type: 'button',
      icon: this.iconId ?? undefined,
      tooltip: this.title,
      onAction: () => this.openDialog(),
    } as const
  }

  asMenuItem() {
    return {
      type: 'menuitem',
      text: this.title,
      icon: this.iconId ?? undefined,
      onAction: () => this.openDialog(),
    } as const
  }

  openDialog(): void {
    addMruToolId(this.id, this.env)
    openToolDialogFor(this)
  }
}

export function parseIconValueFor(toolInfo: RceLtiToolInfo) {
  const result: {
    iconUrl?: string
    canvasIconClass?: string
  } = {}

  const canvasIconClass = toolInfo.canvas_icon_class

  // URL embedded in canvas_icon_class, which happens in some cases (see MAT-1354)
  if (typeof canvasIconClass === 'object') {
    const iconUrl = canvasIconClass?.icon_url

    if (typeof iconUrl === 'string' && iconUrl !== '') {
      result.iconUrl = iconUrl
    }
  }

  // URL at the top level takes precedence
  if (typeof toolInfo.icon_url === 'string' && toolInfo.icon_url !== '') {
    result.iconUrl = toolInfo.icon_url
  }

  // Icon class as string
  if (typeof canvasIconClass === 'string' && canvasIconClass !== '') {
    result.canvasIconClass = canvasIconClass
  }

  return result
}

function registerToolIcon(env: ExternalToolsEnv, toolInfo: RceLtiToolInfo): string | undefined {
  if (env.editor == null) return undefined

  const iconId = 'lti_tool_' + String(toolInfo.id)

  const {iconUrl, canvasIconClass} = parseIconValueFor(toolInfo)

  // We need to strip off the icon- or icon_ prefix from the icon class name to match instui icons
  const iconGlyphName = (canvasIconClass ?? '').replace(/^icon[-_]/, '')

  if (iconUrl != null && iconUrl.length > 0) {
    // Icon image provided
    env.editor.ui.registry.addIcon(iconId, svgImageCache.get(iconUrl))
    return iconId
  } else if (iconGlyphName != null && iconGlyphName.length > 0) {
    // InstUI icon used
    const instUiIcon = instUiIconsArray.find(
      it => it.variant === 'Line' && it.glyphName === iconGlyphName
    )

    if (instUiIcon != null) {
      env.editor.ui.registry.addIcon(iconId, instUiIcon.src)
      return iconId
    }
  }

  // Fallback to default icon
  env.editor.ui.registry.addIcon(iconId, IconLtiSolid.src)
  return iconId
}

const svgImageCache = simpleCache((imageUrl: string) => {
  // Sanitize input against XSS
  const svg = document.createElement('svg')
  svg.setAttribute('viewBox', '0 0 16 16')
  svg.setAttribute('version', '1.1')
  svg.setAttribute('xmlns', 'http://www.w3.org/2000/svg')

  const image = document.createElement('image')
  image.setAttribute('xlink:href', imageUrl)
  image.style.width = '100%'
  image.style.height = '100%'

  svg.appendChild(image)

  return svg.outerHTML
})

/**
 * Loads the list of most recently used external tool ids.
 */
export function loadMruToolIds(): string[] {
  let list: unknown

  try {
    list = JSON.parse(window.localStorage?.getItem('ltimru') ?? '[]')
  } catch (ex) {
    // eslint-disable-next-line no-console
    console.warn('Found bad LTI MRU data', (ex as Error).message)
  }

  return Array.isArray(list) ? list.filter(it => it != null).map(it => String(it)) : []
}

/**
 * Loads the list of most recently used external tool ids.
 */
export function storeMruToolIds(toolIds: string[]): void {
  try {
    window.localStorage?.setItem('ltimru', JSON.stringify(toolIds))
  } catch (ex) {
    // eslint-disable-next-line no-console
    console.warn('Cannot save LTI MRU list', (ex as Error).message)
  }
}

export function addMruToolId(toolId: string, env: ExternalToolsEnv): string[] {
  const initialMruToolIds = loadMruToolIds()

  if (!initialMruToolIds.includes(toolId)) {
    const newToolIds = [toolId, ...initialMruToolIds.slice(0, env.maxMruTools - 1)]
    storeMruToolIds(newToolIds)
    return newToolIds
  }

  return initialMruToolIds
}

export function buildToolMenuItems(
  availableTools: RceToolWrapper[],
  viewAllItem: ExternalToolMenuItem
): ExternalToolMenuItem[] {
  return [
    ...availableTools
      .filter(it => it.isMruTool)
      .map(it => it.asMenuItem())
      .sort((a, b) => a.text.localeCompare(b.text)),
    viewAllItem,
  ]
}
