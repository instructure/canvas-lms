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

import React, {useState, useEffect} from 'react'
import {IconIntegrationsLine} from '@instructure/ui-icons'
import {ContentSelection, Tool} from '../shared/types'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import {openExternalTool} from '@canvas/context-modules/jquery/utils'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = createI18nScope('external_apps_menu_tray')

type ExternalAppsMenuPanelProps = {
  contentSelection: ContentSelection
  onDismiss: () => void
  moduleId: string
}

export default function ExternalAppsMenuPanel({
  contentSelection = {},
  onDismiss,
  moduleId,
}: ExternalAppsMenuPanelProps) {
  const [redirectUrl, setRedirectUrl] = useState<string | null>(null)

  useEffect(() => {
    if (redirectUrl) {
      window.location.href = redirectUrl
    }
  }, [redirectUrl])

  const onSelect = (e: HTMLDivElement, tool: Tool, linkClass: string) => {
    if (linkClass === 'menu_tray_tool_link') {
      openExternalTool({target: e, preventDefault: () => {}})
    } else {
      setRedirectUrl(tool.base_url)
    }
    onDismiss()
  }

  return (
    <>
      <Heading as="h3" level="h3" margin="x-small 0">
        {I18n.t('Select an App')}
      </Heading>
      <View as="ul" role="list" margin="0" padding="small 0 0 0" borderWidth="0 0 small 0">
        {Object.entries(contentSelection).map(([groupKey, tools]) => {
          const sortedTools = [...tools].sort((a, b) => {
            const titleA = a.context_external_tool?.title?.toLowerCase() || ''
            const titleB = b.context_external_tool?.title?.toLowerCase() || ''
            return titleA.localeCompare(titleB)
          })

          return sortedTools.map(({context_external_tool: tool}) => {
            if (!tool) return null
            const linkClass =
              groupKey === 'module_group_menu' || groupKey === 'module_menu_modal'
                ? 'menu_tray_tool_link'
                : 'menu_tool_link'
            const screenReaderText = I18n.t('Launch %{tool}, button.', {tool: tool.title})
            return (
              <View
                key={tool.id}
                as="button"
                id={`ui-id-${moduleId}-${groupKey}`}
                data-tool-id={tool.id}
                data-tool-launch-type={groupKey}
                borderWidth="small 0 0 0"
                width="100%"
                cursor="pointer"
                background="primary"
                padding="small 0"
                textAlign="start"
                onClick={(e: React.MouseEvent<any, MouseEvent>) => {
                  onSelect(e.currentTarget as HTMLDivElement, tool, linkClass)
                }}
                onKeyDown={(e: React.KeyboardEvent<any>) => {
                  if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault()
                    onSelect(e.currentTarget as HTMLDivElement, tool, linkClass)
                  }
                }}
              >
                <View as="span" maxWidth="100%" padding="0 0 0 small">
                  <View margin="0 x-small 0 0" display="inline-block">
                    {tool.icon_url ? (
                      <img
                        className="icon lti_tool_icon"
                        src={tool.icon_url}
                        alt={`${tool?.title} icon`}
                      />
                    ) : (
                      <IconIntegrationsLine />
                    )}
                  </View>
                  <View as="span" display="inline-block">
                    <ScreenReaderContent id={`screen-reader-${tool.id}`}>
                      {screenReaderText}
                    </ScreenReaderContent>
                    {tool.title}
                  </View>
                </View>
              </View>
            )
          })
        })}
      </View>
    </>
  )
}
