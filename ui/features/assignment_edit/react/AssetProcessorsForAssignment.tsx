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

import {render} from '@canvas/react'

import {useEffect} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {AssetProcessorType, ExistingAttachedAssetProcessor} from '@canvas/lti/model/AssetProcessor'
import {
  AssetProcessors,
  AssetProcessorsProps,
} from '@canvas/lti-asset-processor/react/AssetProcessors'
import {
  useAssetProcessorsState,
  useShouldShowAssetProcessors,
} from '@canvas/lti-asset-processor/react/hooks/AssetProcessorsState'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {LtiPlacements} from 'features/developer_keys_v2/model/LtiPlacements'

const I18n = createI18nScope('assignment_edit')
const queryClient = new QueryClient()

type AssetProcessorsPropsWithoutType = Omit<AssetProcessorsProps, 'type'>

export type AssetProcessorsForAssignmentProps = AssetProcessorsPropsWithoutType & {
  initialAttachedProcessors: ExistingAttachedAssetProcessor[]
}

/**
 * AssetProcessors allows the user to attach Asset Processor(s) for an
 * assignment/activity.
 * This method is a shim to mount the React component to integrate it with the
 * EditView backbone code
 */
export function attach({
  container,
  ...elemParams
}: {container: HTMLElement} & AssetProcessorsForAssignmentProps) {
  render(
    <QueryClientProvider client={queryClient}>
      <AssetProcessorsForAssignment {...elemParams} />
    </QueryClientProvider>,
    container,
  )
}

/**
 * Wrapper around AssetProcessors that sets the initial attached processors
 * and provides hidden inputs for use in Assignment edit form
 */
export function AssetProcessorsForAssignment({
  initialAttachedProcessors,
  ...props
}: AssetProcessorsForAssignmentProps) {
  const setFromExistingAttachedProcessors = useAssetProcessorsState(
    s => s.setFromExistingAttachedProcessors,
  )
  useEffect(() => {
    // Neither of the deps will change, so this should only run once
    setFromExistingAttachedProcessors(initialAttachedProcessors)
  }, [initialAttachedProcessors, setFromExistingAttachedProcessors])

  const attachedProcessors = useAssetProcessorsState(s => s.attachedProcessors)

  const shouldShow = useShouldShowAssetProcessors(props.courseId, 'ActivityAssetProcessor')

  if (!shouldShow) {
    return null
  }

  return (
    <div>
      <div className="form-column-left">{I18n.t('Document Processing App(s)')}</div>
      <div className="form-column-right">
        <div className="border border-trbl border-round">
          <AssetProcessors {...props} type="ActivityAssetProcessor" />
        </div>
        {attachedProcessors.map((processor, index) => (
          <input
            key={`asset-processor-input-${processor.id}`}
            data-testid={`asset_processors[${index}]`}
            type="hidden"
            name={`asset_processors[${index}]`}
            value={JSON.stringify(processor.dto)}
          />
        ))}
      </div>
    </div>
  )
}
