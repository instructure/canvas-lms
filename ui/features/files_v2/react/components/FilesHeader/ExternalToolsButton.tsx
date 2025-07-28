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

import React, {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ltiState} from '@canvas/lti/jquery/messages'
import ContentTypeExternalToolTray from '@canvas/trays/react/ContentTypeExternalToolTray'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconArrowOpenDownLine, IconMoreLine} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {useFileManagement} from '../../contexts/FileManagementContext'
import {type Tool} from '@canvas/files_v2/react/modules/filesEnvFactory.types'

const I18n = createI18nScope('files_v2')

export interface ExternalToolsButtonProps {
  buttonDisplay: 'block' | 'inline-block'
  size: 'small' | 'medium' | 'large'
}

const ExternalToolsButton = ({buttonDisplay, size}: ExternalToolsButtonProps) => {
  const [activeTool, setActiveTool] = useState<Tool | null>(null)
  const {fileIndexMenuTools} = useFileManagement()
  const isMobile = size === 'small'

  // Don't render the button if there are no tools
  if (fileIndexMenuTools.length === 0) {
    return null
  }

  const renderMobileButton = () => {
    return (
      <Button display={buttonDisplay} data-testid="lti-index-button">
        <View as="span" margin="0 x-small 0 0">
          {I18n.t('More')}
        </View>
        <IconArrowOpenDownLine />
        <ScreenReaderContent>{I18n.t('External Tools Menu')}</ScreenReaderContent>
      </Button>
    )
  }

  const renderDesktopButton = () => {
    return (
      <IconButton
        renderIcon={IconMoreLine}
        screenReaderLabel={I18n.t('External Tools Menu')}
        data-testid="lti-index-button"
      />
    )
  }

  const iconForTrayTool = (tool: Tool) => {
    if (tool.canvas_icon_class) {
      return <i className={tool.canvas_icon_class} />
    } else if (tool.icon_url) {
      return <img className="icon lti_tool_icon" alt="" src={tool.icon_url} />
    }
    return null
  }

  const handleDismissTray = () => {
    setActiveTool(null)
    if (ltiState?.tray?.refreshOnClose) {
      window.location.reload()
    }
  }

  const handleToolClick = (tool: Tool) => {
    setActiveTool(tool)
  }

  const renderMenuItem = (tool: Tool, index: number) => {
    return (
      <Menu.Item key={`lti-menu-item-${tool.id || index}`} onClick={() => handleToolClick(tool)}>
        <Flex alignItems="center" gap="x-small">
          {iconForTrayTool(tool)}
          <Flex.Item>
            <Text>{tool.title}</Text>
          </Flex.Item>
        </Flex>
      </Menu.Item>
    )
  }

  return (
    <>
      <Menu placement="bottom" trigger={isMobile ? renderMobileButton() : renderDesktopButton()}>
        {fileIndexMenuTools.map((tool: Tool, index: number) => renderMenuItem(tool, index))}
      </Menu>
      <ContentTypeExternalToolTray
        tool={activeTool}
        placement="file_index_menu"
        acceptedResourceTypes={['audio', 'document', 'image', 'video']}
        targetResourceType="document"
        allowItemSelection={false}
        selectableItems={[]}
        onDismiss={handleDismissTray}
        open={activeTool !== null}
        onExternalContentReady={() => {}}
      />
    </>
  )
}

export default ExternalToolsButton
