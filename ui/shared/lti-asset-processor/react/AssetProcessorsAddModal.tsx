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

import {useEffect, useRef} from 'react'
import {Text} from '@instructure/ui-text'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'

import {useScope as createI18nScope} from '@canvas/i18n'
import type {DeepLinkResponse} from '@canvas/deep-linking/DeepLinkResponse'
import {handleExternalContentMessages} from '@canvas/external-tools/messages'
import type {
  LtiLaunchDefinition,
  LtiLaunchPlacement,
} from '@canvas/select-content-dialog/jquery/select_content_dialog'

import {
  AssetProcessorsAddModalState,
  useAssetProcessorsAddModalState,
} from './hooks/AssetProcessorsAddModalState'
import {AssetProcessorsCard} from './AssetProcessorsCards'
import {useAssetProcessorsToolsList} from './hooks/useAssetProcessorsToolsList'
import {onLtiClosePostMessage} from '@canvas/lti/jquery/messages'
import {AssetProcessorType} from '@canvas/lti/model/AssetProcessor'
import {ToolContextName} from './ToolContextName'

const I18n = createI18nScope('asset_processors_selection')

export type AssetProcessorsAddModalOnProcessorResponseFn = ({
  tool,
  data,
}: {
  tool: LtiLaunchDefinition
  data: DeepLinkResponse
}) => void

export type AssetProcessorsAddModalProps = {
  courseId: number
  secureParams: string
  onProcessorResponse: AssetProcessorsAddModalOnProcessorResponseFn
  type: AssetProcessorType
}

export function AssetProcessorsAddModal(props: AssetProcessorsAddModalProps) {
  const stateTag = useAssetProcessorsAddModalState(s => s.state.tag)
  const {close, showToolList} = useAssetProcessorsAddModalState(s => s.actions)

  if (stateTag === 'closed') {
    return null
  }

  return (
    <Modal
      open={true}
      onDismiss={close}
      label={I18n.t('Add A Document Processing App')}
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Header>
        <CloseButton
          elementRef={el => {
            if (el) {
              el.setAttribute('data-pendo', 'asset-processors-add-modal-close-button')
            }
          }}
          onClick={close}
          offset="medium"
          placement="end"
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{I18n.t('Add A Document Processing App')}</Heading>
      </Modal.Header>
      <Modal.Body padding="small">
        <AssetProcessorsAddModalBody {...props} />
      </Modal.Body>
      {assetProcessorsAddModelFooter({tag: stateTag, showToolList})}
    </Modal>
  )
}

type AssetProcessorsAddModelFooterProps = Pick<AssetProcessorsAddModalState, 'tag'> & {
  showToolList: () => void
}

// This can't be a component because <Modal> requires a direct <Modal.Footer> child
function assetProcessorsAddModelFooter({tag, showToolList}: AssetProcessorsAddModelFooterProps) {
  switch (tag) {
    case 'closed':
    case 'toolList':
      return null
    case 'toolLaunch':
      return (
        <Modal.Footer>
          <Button id="asset-processors-add-modal-back-button" onClick={showToolList}>
            {I18n.t('Back')}
          </Button>
        </Modal.Footer>
      )
  }
}

function AssetProcessorsAddModalBody(props: AssetProcessorsAddModalProps) {
  const {courseId} = props
  const {data, isLoading, isError} = useAssetProcessorsToolsList(courseId, props.type)
  const state = useAssetProcessorsAddModalState(s => s.state)

  switch (state.tag) {
    case 'closed':
      return null
    case 'toolList':
      // Loading, error and 'no tools' will be rare: we won't show the modal if there aren't tools
      if (isLoading) {
        return <Text>{I18n.t('Loading document processing apps...')}</Text>
      } else if (isError) {
        return <Text>{I18n.t('Failed to fetch available document processing apps')}</Text>
      } else if (!data?.length) {
        return <Text>{I18n.t('There are no available document processing apps to add.')}</Text>
      } else {
        return <AssetProcessorsAddModalBodyToolList toolList={data} type={props.type} />
      }
    case 'toolLaunch':
      return <AssetProcessorsAddModalBodyToolLaunch {...props} tool={state.tool} />
    case 'invalidDeepLinkingResponse':
      return <Text>{invalidDeepLinkingResponseText(state.tool)}</Text>
  }
}

function AssetProcessorsAddModalBodyToolList({
  toolList,
  type,
}: {
  toolList: LtiLaunchDefinition[]
  type: AssetProcessorType
}) {
  const {launchTool} = useAssetProcessorsAddModalState(s => s.actions)

  // With the default tool size in launch_definitions (from context_external_tool.rb#extension_default_value)
  // make tool list width 800px and the height 463px as calculated from
  // 400px from tool + 63px modal.footer
  return (
    <View as="div" padding="0" width="800px" height="463px" overflowY="auto">
      <Flex direction="column">
        <Flex.Item padding="small">
          <Text weight="bold" size="medium">
            {I18n.t('Choose the document processing app that you wish to add to this assignment.')}
          </Text>
        </Flex.Item>
        {toolList.map((tool, index) => {
          const placementData = getPlacementDataForType(tool, type)
          return (
            <Flex.Item key={index}>
              <AssetProcessorsCard
                icon={{
                  url: placementData?.icon_url,
                  toolName: placementData?.tool_name_for_default_icon || tool.name,
                  toolId: tool.definition_id,
                }}
                title={placementData?.title || tool.name}
                description={tool.description}
                margin="small"
                onClick={() => launchTool(tool)}
              >
                <ToolContextName tool={tool} />
              </AssetProcessorsCard>
            </Flex.Item>
          )
        })}
      </Flex>
    </View>
  )
}

function getPlacementDataForType(
  tool: LtiLaunchDefinition,
  type: AssetProcessorType,
): LtiLaunchPlacement | undefined {
  return tool.placements?.[type]
}

function AssetProcessorsAddModalBodyToolLaunch(
  props: AssetProcessorsAddModalProps & {tool: LtiLaunchDefinition},
) {
  const {courseId, secureParams, onProcessorResponse, tool} = props
  const {close, showInvlidDeepLinkingResponse} = useAssetProcessorsAddModalState(s => s.actions)

  const placement = getPlacementDataForType(tool, props.type)
  const width = placement?.selection_width || '800px'
  const height = placement?.selection_height || '400px'
  const iframeRef = useRef<HTMLIFrameElement>(null)

  useEffect(
    () =>
      handleExternalContentMessages({
        onDeepLinkingResponse: data => {
          try {
            tool && onProcessorResponse({tool, data})
          } catch (e) {
            // Provide debugging output for tool developers to help figure out the problem:
            console.error(e)
            showInvlidDeepLinkingResponse(tool)
            return
          }
          close()
        },
        ready: close,
        cancel: close,
      }),
    [onProcessorResponse, close, tool],
  )

  useEffect(() => {
    return onLtiClosePostMessage(() => iframeRef.current, close)
  }, [close])

  return (
    <iframe
      src={
        `/courses/${courseId}/external_tools/${tool.definition_id}/resource_selection` +
        `?display=borderless&launch_type=${props.type}&secure_params=${secureParams}`
      }
      style={{width, height, border: '0', display: 'block'}}
      title={I18n.t('Configure new document processing app')}
      ref={iframeRef}
    />
  )
}

function invalidDeepLinkingResponseText(tool: LtiLaunchDefinition) {
  return I18n.t(
    'The document processing app %{title} could not be added. Please contact the tool provider.',
    {title: tool.name},
  )
}
