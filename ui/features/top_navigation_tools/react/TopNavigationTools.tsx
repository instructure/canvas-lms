/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React from 'react'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Menu} from '@instructure/ui-menu'
import {IconLtiLine} from '@instructure/ui-icons'
import {Img} from '@instructure/ui-img'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Flex} from '@instructure/ui-flex'
import {Tooltip} from '@instructure/ui-tooltip'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {Tool} from '@canvas/global/env/EnvCommon'

const I18n = useI18nScope('top_navigation_tools')

type TopNavigationToolsProps = {
  tools: Tool[]
  handleToolLaunch: (tool: Tool) => void
}

function getToolIcon(tool: Tool) {
  return (
    (tool.icon_url && (
      <Img src={tool.icon_url} height="1rem" alt={tool.title || 'Tool Icon'} />
    )) || <IconLtiLine title={tool.title || 'Tool Icon'} />
  )
}

function handleToolClick(val: String, tools: Tool[], handleToolLaunch: (tool: Tool) => void) {
  const targeted_tool = tools.find((tool: Tool) => tool.id === val)
  if (targeted_tool) {
    handleToolLaunch(targeted_tool)
  }
}

export function TopNavigationTools(props: TopNavigationToolsProps) {
  const pinned_tools = props.tools.filter(tool => tool.pinned)
  const menu_tools = props.tools.filter(tool => !tool.pinned)

  return (
    <Flex as="div" gap="small" width="100%" height="100%" direction="row-reverse">
      {menu_tools.length > 0 && (
        <Flex.Item>
          <Menu
            placement="bottom end"
            trigger={
              <Tooltip renderTip={I18n.t('LTI Tools Menu')}>
                <Button renderIcon={IconLtiLine} />
              </Tooltip>
            }
            key="menu"
            label={I18n.t('LTI Tools Menu')}
          >
            {menu_tools.map((tool: Tool) => {
              return (
                <Menu.Item
                  onSelect={(e, val) => handleToolClick(val, menu_tools, props.handleToolLaunch)}
                  key={tool.id}
                  value={tool.id}
                  label={I18n.t('Launch %{tool}', {tool: tool.title})}
                >
                  <Flex direction="row" gap="small">
                    {getToolIcon(tool)}
                    <TruncateText>{tool.title}</TruncateText>
                  </Flex>
                </Menu.Item>
              )
            })}
          </Menu>
        </Flex.Item>
      )}
      {pinned_tools.map((tool: Tool) => {
        return (
          <Flex.Item key={tool.id}>
            <Tooltip renderTip={tool.title}>
              <IconButton
                renderIcon={getToolIcon(tool)}
                onClick={e =>
                  handleToolClick(e.target.dataset.toolId, pinned_tools, props.handleToolLaunch)
                }
                data-tool-id={tool.id}
                screenReaderLabel={tool.title}
              />
            </Tooltip>
          </Flex.Item>
        )
      })}
    </Flex>
  )
}

export function MobileTopNavigationTools(props: TopNavigationToolsProps) {
  const pinned_tools = props.tools.filter(tool => tool.pinned)
  const menu_tools = props.tools.filter(tool => !tool.pinned)

  return (
    <Menu
      placement="bottom end"
      trigger={
        <IconButton
          renderIcon={IconLtiLine}
          screenReaderLabel={I18n.t('LTI Tool Menu')}
          withBorder={false}
          withBackground={false}
        />
      }
      key="menu"
    >
      {pinned_tools.map((tool: Tool) => {
        return (
          <Menu.Item
            onSelect={(e, val) => handleToolClick(val, pinned_tools, props.handleToolLaunch)}
            key={tool.id}
            value={tool.id}
            label={I18n.t('Launch %{tool}', {tool: tool.title})}
          >
            <Flex direction="row" gap="small">
              {getToolIcon(tool)}
              <TruncateText>{tool.title}</TruncateText>
            </Flex>
          </Menu.Item>
        )
      })}
      {pinned_tools.length > 0 && menu_tools.length > 0 && <Menu.Separator />}
      {menu_tools.map((tool: Tool) => {
        return (
          <Menu.Item
            onSelect={(e, val) => handleToolClick(val, menu_tools, props.handleToolLaunch)}
            key={tool.id}
            value={tool.id}
            label={I18n.t('Launch %{tool}', {tool: tool.title})}
          >
            <Flex direction="row" gap="small">
              {getToolIcon(tool)}
              <TruncateText>{tool.title}</TruncateText>
            </Flex>
          </Menu.Item>
        )
      })}
    </Menu>
  )
}
