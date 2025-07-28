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

import {Button} from '@instructure/ui-buttons'

import {useScope as createI18nScope} from '@canvas/i18n'

import {Flex} from '@instructure/ui-flex'
import {AssetProcessorsAddModal} from './AssetProcessorsAddModal'
import {AssetProcessorsAttachedProcessorCard} from './AssetProcessorsCards'
import {useAssetProcessorsAddModalState} from './hooks/AssetProcessorsAddModalState'
import {useAssetProcessorsState} from './hooks/AssetProcessorsState'
import {useAssetProcessorsToolsList} from './hooks/useAssetProcessorsToolsList'
import {buildAPDisplayTitle} from '@canvas/lti/model/AssetProcessor'

const I18n = createI18nScope('asset_processors_selection')

export type AssetProcessorsProps = {
  courseId: number
  secureParams: string
  hideErrors?: () => void
}

/**
 * AssetProcessors allows the user to attach Asset Processor(s) for an
 * assignment or discussion. The user chooses the tool (with the
 * appropriate asset processor placement); we then launch the tool and handle
 * the Deep Linking response to keep track of the attached processors.
 */
export function AssetProcessors(props: AssetProcessorsProps) {
  const openAddDialog = useAssetProcessorsAddModalState(s => s.actions.showToolList)
  const toolsAvailable = !!useAssetProcessorsToolsList(props.courseId).data?.length
  const {attachedProcessors, addAttachedProcessors, deleteAttachedProcessor} =
    useAssetProcessorsState(s => s)

  return (
    <>
      {toolsAvailable && (
        <AssetProcessorsAddModal onProcessorResponse={addAttachedProcessors} {...props} />
      )}
      <Flex direction="column" gap="small">
        {attachedProcessors.map((processor, index) => (
          <AssetProcessorsAttachedProcessorCard
            assetProcessorId={processor.id}
            key={index}
            icon={{
              toolId: processor.toolId,
              toolName: processor.toolName || '',
              url: processor.iconOrToolIconUrl,
            }}
            title={buildAPDisplayTitle(processor)}
            description={processor.text}
            windowSettings={processor.window}
            iframeSettings={processor.iframe}
            onDelete={() => deleteAttachedProcessor(index, props.hideErrors)}
          ></AssetProcessorsAttachedProcessorCard>
        ))}
        <span
          data-testid="asset-processor-errors"
          id="asset_processors_errors"
          className="error-message"
        />
        {toolsAvailable && (
          <span>
            <Button color="secondary" onClick={openAddDialog} id="asset-processor-add-button">
              {I18n.t('Add Document Processing App')}
            </Button>
          </span>
        )}
      </Flex>
    </>
  )
}
