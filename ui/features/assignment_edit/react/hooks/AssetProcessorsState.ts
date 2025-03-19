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

import {create} from "zustand"

import {AssetProcessorContentItemDto, AssetProcessorContentItem, assetProcessorContentItemToDto} from "@canvas/deep-linking/models/AssetProcessorContentItem"
import {LtiLaunchDefinition} from "@canvas/select-content-dialog/jquery/select_content_dialog"
import {useScope as createI18nScope} from '@canvas/i18n'
import {confirmDanger} from "@canvas/instui-bindings/react/Confirm"
import {DeepLinkResponse} from "@canvas/deep-linking/DeepLinkResponse"

const I18n = createI18nScope('asset_processors_selection')

export type AssetProcessorsState = {
  attachedProcessors: AttachedAssetProcessor[],

  addAttachedProcessors:
    ({ tool, data }: { tool: LtiLaunchDefinition, data: DeepLinkResponse }) => void,
  deleteAttachedProcessor: (index: number) => Promise<void>,
  setFromExistingAttachedProcessors: (processors: ExistingAttachedAssetProcessor[]) => void,
}

/**
 * Object sent to server when saving (creating/updating) an assignment. Needs to match up
 * with the format expected by the ruby code.
 */
type AttachedAssetProcessorDto = {
  existing_id: number
} | {
  new_content_item: AssetProcessorContentItemDto
}

// Ensure types, while avoiding serializing JSON every render
const jsonStringifyDto: (blob: AttachedAssetProcessorDto) => string = JSON.stringify

/*
 * Info needed to render an attached asset processor, whether it come from
 * an existing processor already on the assignment, or from one newly
 * added from a tool launch
 */
export type AttachedAssetProcessor = {
  toolName?: string,
  toolId: string,
  iconUrl?: string,
  title?: string,
  text?: string,

  // JSON-serialized Asset Processor (AttachedAssetProcessorDto) to be sent to server
  dtoJson: string,
}

/**
 * Data sent by server to show APs already attached to an existing assignment.
 * See Lti::AssetProcessors.processors_info_for_assignment_edit_page
 */
export type ExistingAttachedAssetProcessor = {
  id: number,
  title?: string,
  text?: string,
  icon?: AssetProcessorContentItem['icon'],
  context_external_tool_id: number
  context_external_tool_name?: string,
}

function newAttachedAssetProcessor(
  {tool, contentItem}: {tool: LtiLaunchDefinition, contentItem: AssetProcessorContentItem }
): AttachedAssetProcessor {
  return {
    toolName: tool.name,
    toolId: tool.definition_id,
    iconUrl: safeDigIconUrl(contentItem.icon) || tool.placements?.ActivityAssetProcessor?.icon_url,
    title: contentItem.title,
    text: contentItem.text,
    dtoJson: jsonStringifyDto({
      new_content_item: assetProcessorContentItemToDto(contentItem, tool.definition_id)
    })
  }
}

// TODO: we'll probably want to do real validation on the whole content item,
// at least on the server. See INTEROP-9255
function safeDigIconUrl(icon: any): string | undefined {
  if (typeof icon === 'object' && icon && typeof icon.url === 'string') {
    return icon.url
  }
}

function existingAttachedAssetProcessor(
  processor: ExistingAttachedAssetProcessor
): AttachedAssetProcessor {
  return {
    toolName: processor.context_external_tool_name,
    toolId: processor.context_external_tool_id.toString(),
    iconUrl: processor.icon?.url,
    title: processor.title,
    text: processor.text,
    dtoJson: jsonStringifyDto({existing_id: processor.id})
  }
}

export const useAssetProcessorsState = create<AssetProcessorsState>((set, get) => ({
  attachedProcessors: [],

  addAttachedProcessors({tool, data}) {
    // TODO handle msg, errors, anything else in DeepLinkResponse
    const items = data.content_items.filter(item => item.type === 'ltiAssetProcessor')
    const newProcessors: AttachedAssetProcessor[] = items.map(contentItem => newAttachedAssetProcessor({tool, contentItem}))
    set({attachedProcessors: [...get().attachedProcessors, ...newProcessors]})
  },

  deleteAttachedProcessor: async (index: number) => {
    const attachedProcessors = get().attachedProcessors
    const processor = attachedProcessors[index]

    const title = I18n.t("Confirm Delete")
    const msg = I18n.t(
      "Are you sure you'd like to delete *%{title}*? Deleting %{title} will will prevent future submissions from being processed by them as well as removing any existing reports by %{title} from your Speedgrader view.",
      {title: processor.title, wrapper: '<strong>$1</strong>'}
    )
    const messageDangerouslySetInnerHTML = { __html: msg }
    const confirmButtonLabel = I18n.t("Delete")
    if (await confirmDanger({ title, message: null, messageDangerouslySetInnerHTML, confirmButtonLabel })) {
      set({attachedProcessors: get().attachedProcessors.filter((_, i) => i !== index)})
    }
  },

  setFromExistingAttachedProcessors: (processors) =>
    set({attachedProcessors: processors.map(existingAttachedAssetProcessor)}),
}))
