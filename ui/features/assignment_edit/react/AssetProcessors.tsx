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
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {createRoot} from 'react-dom/client'

import {useScope as createI18nScope} from '@canvas/i18n'

import {Flex} from '@instructure/ui-flex'
import {useEffect} from 'react'
import {AssetProcessorsAddModal} from './AssetProcessorsAddModal'
import {AssetProcessorsAttachedProcessorCard} from './AssetProcessorsCards'
import {useAssetProcessorsAddModalState} from './hooks/AssetProcessorsAddModalState'
import {useAssetProcessorsState} from './hooks/AssetProcessorsState'
import {useAssetProcessorsToolsList} from './hooks/useAssetProcessorsToolsList'
import {buildAPDisplayTitle, ExistingAttachedAssetProcessor} from '@canvas/lti/model/AssetProcessor'

const I18n = createI18nScope('asset_processors_selection')

const queryClient = new QueryClient()

export type AssetProcessorsProps = {
  courseId: number
  secureParams: string
  initialAttachedProcessors: ExistingAttachedAssetProcessor[]
  hideErrors: () => void
}

/**
 * AssetProcessors allows the user to attach Asset Processor(s) for an
 * assignment/activity. The user chooses the tool (with the ActivityAssetProcessor)
 * placement; we then launch the tool and handle the Deep Linking response to
 * keep track of the attached processors.
 *
 * This method is a shim to mount the React component to integrate it with the
 * EditView backbone code
 */
export function attach({
  container,
  ...elemParams
}: {container: HTMLElement} & AssetProcessorsProps) {
  createRoot(container).render(
    <QueryClientProvider client={queryClient}>
      <AssetProcessors {...elemParams} />
    </QueryClientProvider>,
  )
}

export function AssetProcessors(props: AssetProcessorsProps) {
  const openAddDialog = useAssetProcessorsAddModalState(s => s.actions.showToolList)
  const toolsAvailable = !!useAssetProcessorsToolsList(props.courseId).data?.length
  const {
    attachedProcessors,
    addAttachedProcessors,
    deleteAttachedProcessor,
    setFromExistingAttachedProcessors,
  } = useAssetProcessorsState(s => s)

  useEffect(() => {
    // Neither of the deps will change, so this should only run once
    setFromExistingAttachedProcessors(props.initialAttachedProcessors)
  }, [props.initialAttachedProcessors, setFromExistingAttachedProcessors])

  if (!toolsAvailable && !attachedProcessors.length) {
    // No tools available, or we are still loading, or there was an error fetching
    return null
  }

  return (
    <div>
      <div className="form-column-left">{I18n.t('Document processing apps')}</div>
      <div className="form-column-right">
        <div className="border border-trbl border-round">
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
              >
                <input
                  data-testid={`asset_processors[${index}]`}
                  type="hidden"
                  name={`asset_processors[${index}]`}
                  value={processor.dtoJson}
                />
              </AssetProcessorsAttachedProcessorCard>
            ))}
            <span
              data-testid="asset-processor-errors"
              id="asset_processors_errors"
              className="error-message"
            />
            <span>
              <Button color="secondary" onClick={openAddDialog} id="asset-processor-add-button">
                {I18n.t('Add Document Processing App')}
              </Button>
            </span>
          </Flex>
          {toolsAvailable && (
            <AssetProcessorsAddModal onProcessorResponse={addAttachedProcessors} {...props} />
          )}
        </div>
      </div>
    </div>
  )
}
