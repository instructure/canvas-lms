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

import {create} from 'zustand'

import {showFlashAlert, showFlashError} from '@canvas/alerts/react/FlashAlert'
import {DeepLinkResponse} from '@canvas/deep-linking/DeepLinkResponse'
import {
  AssetProcessorContentItem,
  AssetProcessorContentItemDto,
  assetProcessorContentItemToDto,
} from '@canvas/deep-linking/models/AssetProcessorContentItem'

import {
  AssetProcessorWindowSettings,
  ExistingAttachedAssetProcessor,
  safeDigIconUrl,
  ZAssetProcessorContentItem,
} from '@canvas/lti/model/AssetProcessor'
import {IframeDimensions} from '@canvas/lti/model/common'
import {useScope as createI18nScope} from '@canvas/i18n'
import {confirmDanger} from '@canvas/instui-bindings/react/Confirm'
import {LtiLaunchDefinition} from '@canvas/select-content-dialog/jquery/select_content_dialog'

const I18n = createI18nScope('asset_processors_selection')

export type AssetProcessorsState = {
  attachedProcessors: AttachedAssetProcessor[]

  addAttachedProcessors: ({tool, data}: {tool: LtiLaunchDefinition; data: DeepLinkResponse}) => void
  deleteAttachedProcessor: (index: number, onDelete: () => void) => Promise<void>
  setFromExistingAttachedProcessors: (processors: ExistingAttachedAssetProcessor[]) => void
}

/**
 * Object sent to server when saving (creating/updating) an assignment. Needs to match up
 * with the format expected by the ruby code.
 */
type AttachedAssetProcessorDto =
  | {
      existing_id: number
    }
  | {
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
  id?: number
  toolName: string
  toolPlacementLabel?: string
  toolId: string
  iconOrToolIconUrl?: string
  title?: string
  text?: string
  window?: AssetProcessorWindowSettings
  iframe?: IframeDimensions

  // JSON-serialized Asset Processor (AttachedAssetProcessorDto) to be sent to server
  dtoJson: string
}

function newAttachedAssetProcessor({
  tool,
  contentItem,
}: {tool: LtiLaunchDefinition; contentItem: AssetProcessorContentItem}): AttachedAssetProcessor {
  return {
    toolId: tool.definition_id,
    // tool.name in LtiLaunchDefinitions is not really tool name, it's the placement title
    toolName: tool.placements.ActivityAssetProcessor!.tool_name_for_default_icon || tool.name,
    toolPlacementLabel: tool.placements.ActivityAssetProcessor!.title,
    iconOrToolIconUrl:
      safeDigIconUrl(contentItem.icon) || tool.placements.ActivityAssetProcessor!.icon_url,
    text: contentItem.text,
    title: contentItem.title,
    iframe: contentItem.iframe,
    window: contentItem.window,
    dtoJson: jsonStringifyDto({
      new_content_item: assetProcessorContentItemToDto(contentItem, tool.definition_id),
    }),
  }
}

function existingAttachedAssetProcessor(
  processor: ExistingAttachedAssetProcessor,
): AttachedAssetProcessor {
  return {
    id: processor.id,
    toolName: processor.tool_name,
    toolPlacementLabel: processor.tool_placement_label,
    toolId: processor.tool_id.toString(),
    iconOrToolIconUrl: processor.icon_or_tool_icon_url,
    title: processor.title,
    text: processor.text,
    iframe: processor.iframe,
    window: processor.window,
    dtoJson: jsonStringifyDto({existing_id: processor.id}),
  }
}

function showFlashMessagesFromDeepLinkingResponse(data: DeepLinkResponse) {
  if (data.errormsg) {
    showFlashError(
      I18n.t('Error from document processing app: %{errorFromTool}', {
        errorFromTool: data.errormsg,
      }),
    )()
  }

  if (data.msg) {
    showFlashAlert({
      message: I18n.t('Message from document processing app: %{messageFromTool}', {
        messageFromTool: data.msg,
      }),
    })
  }

  if (!data.msg && !data.errormsg && !data.content_items?.length) {
    showFlashAlert({
      message: I18n.t('The document processing app returned with no processors to attach.'),
    })
  }
}

export const useAssetProcessorsState = create<AssetProcessorsState>((set, get) => ({
  attachedProcessors: [],

  addAttachedProcessors({tool, data}) {
    showFlashMessagesFromDeepLinkingResponse(data)

    const items = data.content_items.filter(item => item.type === 'ltiAssetProcessor')

    items.forEach(item => ZAssetProcessorContentItem.parse(item))

    const newProcessors: AttachedAssetProcessor[] = items.map(contentItem =>
      newAttachedAssetProcessor({tool, contentItem}),
    )
    set({attachedProcessors: [...get().attachedProcessors, ...newProcessors]})
  },

  deleteAttachedProcessor: async (index: number, onDelete?: () => void) => {
    const attachedProcessors = get().attachedProcessors
    const processor = attachedProcessors[index]

    const title = I18n.t('Confirm Delete')
    const msg = I18n.t(
      "Are you sure you'd like to delete *%{title}*? Deleting %{title} will will prevent future submissions from being processed by them as well as removing any existing reports by %{title} from your Speedgrader view.",
      {title: processor.title, wrapper: '<strong>$1</strong>'},
    )
    const messageDangerouslySetInnerHTML = {__html: msg}
    const confirmButtonLabel = I18n.t('Delete')
    if (
      await confirmDanger({
        title,
        message: null,
        messageDangerouslySetInnerHTML,
        confirmButtonLabel,
      })
    ) {
      set({attachedProcessors: get().attachedProcessors.filter((_, i) => i !== index)})
      onDelete?.()
    }
  },

  setFromExistingAttachedProcessors: processors =>
    set({attachedProcessors: processors.map(existingAttachedAssetProcessor)}),
}))
