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

import {Text} from '@instructure/ui-text'
import {Flex} from "@instructure/ui-flex"
import {View} from "@instructure/ui-view"

import {useScope as createI18nScope} from '@canvas/i18n'
import TruncateWithTooltip from "@canvas/lti-apps/components/common/TruncateWithTooltip"
import {ToolIconOrDefault} from "@canvas/lti-apps/components/common/ToolIconOrDefault"
import {Spacing} from '@instructure/emotion'
import {Menu} from '@instructure/ui-menu'
import {IconButton} from '@instructure/ui-buttons'
import {IconMoreLine} from '@instructure/ui-icons'

const I18n = createI18nScope('asset_processors_selection')

type AttachedAssetProcessorsMenuProps = {
  nameForScreenReader: string
  onDelete: () => void
}

const AttachedAssetProcessorsMenu = ({nameForScreenReader, onDelete}: AttachedAssetProcessorsMenuProps) => {
  return (
    <Menu
      trigger={
        <IconButton
          renderIcon={IconMoreLine}
          withBackground={false}
          withBorder={false}
          screenReaderLabel={
            I18n.t('Actions for document processing app: %{documentProcessingAppName}',
            {documentProcessingAppName: nameForScreenReader}
          )}
        />
      }
      onSelect={(_e, value) => {
        if (value === 'delete') {
          onDelete()
        }
      }}
    >
      <Menu.Item value="modify">
        <View padding="0 x-large 0 small">
          {I18n.t('Modify')}
        </View>
      </Menu.Item>
      <Menu.Item value="delete">
        <View padding="0 x-large 0 small">
          {I18n.t('Delete')}
        </View>
      </Menu.Item>
    </Menu>
  )
}

export const AssetProcessorsAttachedProcessorCard = (
  {onModify, onDelete, title, ...commonProps}: AssetProcessorsAttachedProcessorCardProps
) => {
  const {toolName} = commonProps.icon
  let completeTitle: string
  if (title && toolName && title !== toolName) {
    completeTitle = (`${toolName} · ${title}`)
  } else {
    completeTitle = title || toolName
  }

  return (
    <AssetProcessorsCard
      {...commonProps}
      title={completeTitle}
      extraColumns={
        <div style={{flex: "none"}}>
          <AttachedAssetProcessorsMenu nameForScreenReader={completeTitle} onDelete={onDelete} />
        </div>
      }
    />
  )
}

type AssetProcessorsCardCommonProps = {
  icon: {
    url: string | null | undefined,
    toolName: string,
    toolId: number | string
  },
  description?: string,
  margin?: Spacing,
  children?: React.ReactNode,
}

type AssetProcessorsCardProps = AssetProcessorsCardCommonProps & {
  title: string,
  extraColumns?: React.ReactNode
  onClick?: () => void,
}

type AssetProcessorsAttachedProcessorCardProps = AssetProcessorsCardCommonProps & {
  title?: string,
  onModify: () => void,
  onDelete: () => void,
}

export const AssetProcessorsCard = (
  {icon, title, description, children, onClick, extraColumns: extraColumns, margin}: AssetProcessorsCardProps
) => (
  <View
    aria-label={title}
    as="div"
    background="secondary"
    borderRadius="medium"
    borderWidth="none"
    {...onClick ? {cursor: "pointer"} : undefined}
    margin={margin}
    onClick={onClick}
    padding="mediumSmall"
    position="relative"
    role={onClick ? 'button' : undefined}
    tabIndex={onClick ? 0 : undefined}
  >
    <Flex direction="column" height="100%">
      <Flex
        margin="0" {...{
          alignItems: description ? "start" : undefined
        }}>
        <div style={{borderRadius: '8px', overflow: 'hidden', flex: "none"}}>
          <ToolIconOrDefault size={36} toolId={icon.toolId} margin={1} marginRight="1.4em" toolName={icon.toolName} iconUrl={icon.url} />
        </div>
        <div style={{overflow: "hidden", flex: 1}}>
          <div style={{marginRight: "1.4em"}}>
            <TruncateWithTooltip
               linesAllowed={2}
               horizontalOffset={0}
               backgroundColor="primary-inverse"
             >
              <Text weight="bold" size="medium">
                {title}
              </Text>
            </TruncateWithTooltip>
          </div>
          {description ?
            <div style={{marginTop: "0.75em", marginRight: "1.4em"}}>
              <TruncateWithTooltip
                 linesAllowed={4}
                 horizontalOffset={0}
                 backgroundColor="primary-inverse"
               >
               {description}
              </TruncateWithTooltip>
            </div> : null
          }
          {children}
        </div>
        {extraColumns}
      </Flex>
    </Flex>
  </View>
)
