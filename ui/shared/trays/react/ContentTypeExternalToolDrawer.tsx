//
// Copyright (C) 2024 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under the
// terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

import React, {useEffect, useRef} from 'react'
import $ from 'jquery'
import {CloseButton} from '@instructure/ui-buttons'
import {DrawerLayout} from '@instructure/ui-drawer-layout'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconLtiLine} from '@instructure/ui-icons'
import {Img} from '@instructure/ui-img'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'
import {handleExternalContentMessages} from '@canvas/external-tools/messages'
import ToolLaunchIframe from '@canvas/external-tools/react/components/ToolLaunchIframe'

type Tool = {
  id: string
  title: string
  base_url: string
  icon_url: string
}

type KnownResourceType =
  | 'assignment'
  | 'assignment_group'
  | 'audio'
  | 'discussion_topic'
  | 'document'
  | 'image'
  | 'module'
  | 'quiz'
  | 'page'
  | 'video'

export type SelectableItem = {
  course_id: string
  type: KnownResourceType
}

type Props = {
  tool: Tool
  pageContent: Element
  pageContentTitle: string
  pageContentMinWidth: string
  pageContentHeight: string
  trayPlacement: string
  acceptedResourceTypes: KnownResourceType[]
  targetResourceType: KnownResourceType
  allowItemSelection: boolean
  selectableItems: SelectableItem[]
  onDismiss: any
  onExternalContentReady: any
  open: boolean
  placement: string
  extraQueryParams?: {}
}

export default function ContentTypeExternalToolDrawer({
  tool,
  pageContent,
  pageContentTitle,
  pageContentMinWidth,
  pageContentHeight,
  trayPlacement,
  acceptedResourceTypes,
  targetResourceType,
  allowItemSelection,
  selectableItems,
  onDismiss,
  onExternalContentReady,
  open,
  placement,
  extraQueryParams = {},
}: Props) {
  const queryParams = {
    com_instructure_course_accept_canvas_resource_types: acceptedResourceTypes,
    com_instructure_course_canvas_resource_type: targetResourceType,
    com_instructure_course_allow_canvas_resource_selection: allowItemSelection,
    com_instructure_course_available_canvas_resources: selectableItems,
    display: 'borderless',
    placement,
    ...extraQueryParams,
  }
  const prefix = tool?.base_url.indexOf('?') === -1 ? '?' : '&'
  const iframeUrl = `${tool?.base_url}${prefix}${$.param(queryParams)}`
  const toolTitle = tool ? tool.title : 'External Tool'
  const toolIconUrl = tool ? tool.icon_url : ''
  const toolIconAlt = toolTitle ? `${toolTitle} icon` : ''
  const iframeRef = useRef()
  const pageContentRef = useRef()

  useEffect(
    // setup DrawerLayout content
    () => {
      // appends pageContent to DrawerLayout.content
      if (pageContentRef.current && pageContent) {
        pageContentRef.current.appendChild(pageContent)
      }
    },
    [pageContent]
  )

  useEffect(
    // returns cleanup function:
    () => handleExternalContentMessages({ready: onExternalContentReady}),
    [onExternalContentReady]
  )

  return (
    <View display="block" height={pageContentHeight}>
      <DrawerLayout minWidth={pageContentMinWidth}>
        <DrawerLayout.Content label={pageContentTitle}>
          <div ref={pageContentRef} />
        </DrawerLayout.Content>
        <DrawerLayout.Tray
          label="Right Side Tray"
          open={open}
          placement={trayPlacement}
          onDismiss={onDismiss}
          data-testid="drawer-layout-tray"
          shouldCloseOnDocumentClick={false}
          themeOverride={{
            zIndex: '50',
          }}
        >
          <Flex
            height="1.5rem"
            justifyItems="space-between"
            alignItems="center"
            padding="medium small medium small"
            width="320px"
          >
            <Flex.Item padding="none small none none">
              {(toolIconUrl && <Img src={toolIconUrl} height="1rem" alt={toolIconAlt} />) || (
                <IconLtiLine />
              )}
            </Flex.Item>
            <Flex.Item shouldShrink={true} shouldGrow={true}>
              <Heading level="h4">
                <TruncateText>{toolTitle}</TruncateText>
              </Heading>
            </Flex.Item>
            <Flex.Item padding="none none none small">
              <CloseButton size="small" onClick={onDismiss} screenReaderLabel="Close" />
            </Flex.Item>
          </Flex>
          <ToolLaunchIframe
            data-testid="ltiIframe"
            ref={iframeRef}
            src={iframeUrl}
            title={toolTitle}
          />
        </DrawerLayout.Tray>
      </DrawerLayout>
    </View>
  )
}
