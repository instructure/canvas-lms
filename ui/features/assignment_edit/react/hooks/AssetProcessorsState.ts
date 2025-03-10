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

import {AssetProcessorContentItem} from "@canvas/deep-linking/models/AssetProcessorContentItem"
import {LtiLaunchDefinition} from "@canvas/select-content-dialog/jquery/select_content_dialog"
import {useScope as createI18nScope} from '@canvas/i18n'
import {confirmDanger} from "@canvas/instui-bindings/react/Confirm"
import {DeepLinkResponse} from "@canvas/deep-linking/DeepLinkResponse"

const I18n = createI18nScope('asset_processors_selection')

type AttachedAssetProcessor = {
  tool: LtiLaunchDefinition,
  contentItem: AssetProcessorContentItem,
}

type AssetProcessorsState = {
  attachedProcessors: AttachedAssetProcessor[],

  addAttachedProcessors:
    ({ tool, data }: { tool: LtiLaunchDefinition, data: DeepLinkResponse }) => void,
  deleteAttachedProcessor: (index: number) => Promise<void>,
}

export const useAssetProcessorsState = create<AssetProcessorsState>((set, get) => ({
  attachedProcessors: [],

  addAttachedProcessors({tool, data}) {
    // TODO handle msg, errors, anything else in DeepLinkResponse
    const items = data.content_items.filter(item => item.type === 'ltiAssetProcessor')
    const newProcessors = items.map(contentItem => ({tool, contentItem}))
    set({attachedProcessors: [...get().attachedProcessors, ...newProcessors]})
  },

  deleteAttachedProcessor: async (index: number) => {
    const attachedProcessors = get().attachedProcessors
    const processor = attachedProcessors[index]

    const title = I18n.t("Confirm Delete")
    const msg = I18n.t(
      "Are you sure you'd like to delete *%{title}*? Deleting %{title} will will prevent future submissions from being processed by them as well as removing any existing reports by %{title} from your Speedgrader view.",
      {title: processor.contentItem.title, wrapper: '<strong>$1</strong>'}
    )
    const messageDangerouslySetInnerHTML = { __html: msg }
    const confirmButtonLabel = I18n.t("Delete")
    if (await confirmDanger({ title, message: null, messageDangerouslySetInnerHTML, confirmButtonLabel })) {
      set({attachedProcessors: get().attachedProcessors.filter((_, i) => i !== index)})
    }
  }
}))
