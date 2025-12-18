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
  AssetProcessorType,
  ExistingAttachedAssetProcessor,
  safeDigIconUrl,
  ZAssetProcessorContentItem,
} from '@canvas/lti/model/AssetProcessor'
import {IframeDimensions} from '@canvas/lti/model/common'
import {useScope as createI18nScope} from '@canvas/i18n'
import {confirmDanger} from '@canvas/instui-bindings/react/Confirm'
import {
  LtiLaunchDefinition,
  LtiLaunchPlacement,
} from '@canvas/select-content-dialog/jquery/select_content_dialog'
import {useAssetProcessorsToolsList} from './useAssetProcessorsToolsList'

const I18n = createI18nScope('asset_processors_selection')

export enum ContentItemType {
  LtiAssetProcessor = 'ltiAssetProcessor',
  LtiAssetProcessorContribution = 'ltiAssetProcessorContribution',
}

export type AssetProcessorsState = {
  attachedProcessors: AttachedAssetProcessor[]

  addAttachedProcessors: ({
    tool,
    data,
    type,
  }: {
    tool: LtiLaunchDefinition
    data: DeepLinkResponse
    type: AssetProcessorType
  }) => void
  removeAttachedProcessor: (index: number, onRemove?: () => void) => Promise<void>
  setFromExistingAttachedProcessors: (processors: ExistingAttachedAssetProcessor[]) => void
}

/**
 * Object sent to server when saving (creating/updating) an assignment. Needs to match up
 * with the format expected by the ruby code.
 */
export type AttachedAssetProcessorDto =
  | {
      existing_id: number
    }
  | {
      new_content_item: AssetProcessorContentItemDto
    }

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

  // Asset Processor (AttachedAssetProcessorDto) to be sent to server
  // (non-graphql API -- assignment edit page)
  dto: AttachedAssetProcessorDto
}

function newAttachedAssetProcessor({
  tool,
  contentItem,
}: {
  tool: LtiLaunchDefinition
  contentItem: AssetProcessorContentItem
}): AttachedAssetProcessor {
  const placement = placementData(tool, placementForContentItemType(contentItem))
  return {
    toolId: tool.definition_id,
    // tool.name in LtiLaunchDefinitions is not really tool name, it's the placement title
    toolName: placement?.tool_name_for_default_icon || tool.name,
    toolPlacementLabel: placement?.title,
    iconOrToolIconUrl: safeDigIconUrl(contentItem.icon) || placement?.icon_url,
    text: contentItem.text,
    title: contentItem.title,
    iframe: contentItem.iframe,
    window: contentItem.window,
    dto: {
      new_content_item: assetProcessorContentItemToDto(contentItem, tool.definition_id),
    },
  }
}

function placementForContentItemType(contentItem: AssetProcessorContentItem): AssetProcessorType {
  return contentItem.type === ContentItemType.LtiAssetProcessor
    ? 'ActivityAssetProcessor'
    : 'ActivityAssetProcessorContribution'
}

function placementData(
  tool: LtiLaunchDefinition,
  type: AssetProcessorType,
): LtiLaunchPlacement | undefined {
  return tool.placements?.[type]
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
    dto: {existing_id: processor.id},
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

  addAttachedProcessors({tool, data, type}) {
    showFlashMessagesFromDeepLinkingResponse(data)

    const allowedType =
      type === 'ActivityAssetProcessor'
        ? ContentItemType.LtiAssetProcessor
        : ContentItemType.LtiAssetProcessorContribution

    const newProcessors = data.content_items
      .filter(item => item.type === allowedType)
      .map(item => ZAssetProcessorContentItem.parse(item))
      .map(contentItem => newAttachedAssetProcessor({tool, contentItem}))

    set({attachedProcessors: [...get().attachedProcessors, ...newProcessors]})
  },

  removeAttachedProcessor: async (index: number, onRemove?: () => void) => {
    const attachedProcessors = get().attachedProcessors
    const processor = attachedProcessors[index]

    const title = I18n.t('Confirm Removal')
    const msg = I18n.t(
      "Are you sure you'd like to remove *%{title}*? Removing %{title} will prevent future submissions from being processed by them as well as removing any existing reports by %{title} from your Speedgrader view.",
      {title: processor.title, wrapper: '<strong>$1</strong>'},
    )
    const messageDangerouslySetInnerHTML = {__html: msg}
    const confirmButtonLabel = I18n.t('Remove')
    if (
      await confirmDanger({
        title,
        message: null,
        messageDangerouslySetInnerHTML,
        confirmButtonLabel,
      })
    ) {
      set({attachedProcessors: get().attachedProcessors.filter((_, i) => i !== index)})
      onRemove?.()
    }
  },

  setFromExistingAttachedProcessors: processors =>
    set({attachedProcessors: processors.map(existingAttachedAssetProcessor)}),
}))

/**
 * Returns true if there are any asset processors attached to the assignment or
 * discussion, or if there are tools available to attach.
 */
export function useShouldShowAssetProcessors(courseId: number, type: AssetProcessorType): boolean {
  const attachedProcessors = useAssetProcessorsState(s => s.attachedProcessors)
  const toolsAvailable = !!useAssetProcessorsToolsList(courseId, type).data?.length
  return toolsAvailable || attachedProcessors.length > 0
}
