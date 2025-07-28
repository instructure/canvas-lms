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

import type {AssetProcessorWindowSettings} from '@canvas/lti/model/AssetProcessor'
import ExternalToolModalLauncher from '@canvas/external-tools/react/components/ExternalToolModalLauncher'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ToolIconOrDefault} from '@canvas/lti-apps/components/common/ToolIconOrDefault'
import TruncateWithTooltip from '@canvas/lti-apps/components/common/TruncateWithTooltip'
import type {IframeDimensions} from '@canvas/lti/model/common'
import type {Spacing} from '@instructure/emotion'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconExternalLinkLine, IconMoreLine} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {isNil} from 'lodash'
import {useState} from 'react'

const I18n = createI18nScope('asset_processors_selection')

type AttachedAssetProcessorsMenuProps = {
  modifyInNewWindow: boolean
  nameForScreenReader: string
  onModify?: () => void
  onDelete: () => void
}

type AssetProcessorsCardCommonProps = {
  icon: {
    url: string | null | undefined
    toolName: string
    toolId: number | string
  }
  title: string
  description?: string
  margin?: Spacing
  children?: React.ReactNode
}

type AssetProcessorsCardProps = AssetProcessorsCardCommonProps & {
  extraColumns?: React.ReactNode
  onClick?: () => void
}

type AssetProcessorsAttachedProcessorCardProps = AssetProcessorsCardCommonProps & {
  assetProcessorId?: number
  onDelete: () => void
  iframeSettings?: IframeDimensions
  windowSettings?: AssetProcessorWindowSettings
}

const AttachedAssetProcessorsMenu = ({
  modifyInNewWindow,
  nameForScreenReader,
  onModify,
  onDelete,
}: AttachedAssetProcessorsMenuProps) => {
  return (
    <Menu
      trigger={
        <IconButton
          data-pendo="asset-processor-menu-button"
          renderIcon={IconMoreLine}
          withBackground={false}
          withBorder={false}
          screenReaderLabel={I18n.t(
            'Actions for document processing app: %{documentProcessingAppName}',
            {documentProcessingAppName: nameForScreenReader},
          )}
        />
      }
      onSelect={(_e, value) => {
        if (value === 'delete') {
          onDelete()
        } else if (value === 'modify') {
          onModify?.()
        }
      }}
    >
      {onModify && (
        <Menu.Item data-pendo="asset-processor-modify-button" value="modify">
          <View padding="0 x-large 0 small">
            {I18n.t('Modify')}
            {modifyInNewWindow && (
              <IconExternalLinkLine
                size="x-small"
                data-testid="external-link-icon"
                style={{marginLeft: '.5rem'}}
              />
            )}
          </View>
        </Menu.Item>
      )}
      <Menu.Item data-pendo="asset-processor-delete-button" value="delete">
        <View padding="0 x-large 0 small">{I18n.t('Delete')}</View>
      </Menu.Item>
    </Menu>
  )
}

export const AssetProcessorsAttachedProcessorCard = ({
  assetProcessorId,
  iframeSettings,
  onDelete,
  windowSettings,
  ...commonProps
}: AssetProcessorsAttachedProcessorCardProps) => {
  const [settingsLaunchModalVisible, setSettingsLaunchModalVisible] = useState<boolean>(false)
  const {title} = commonProps
  const modifyInNewWindow = !isNil(windowSettings)

  function onModify() {
    if (modifyInNewWindow) {
      const url = `/asset_processors/${assetProcessorId}/launch`
      const targetName = windowSettings.targetName || '_blank'

      let features = ''
      if (windowSettings.windowFeatures) {
        features = windowSettings.windowFeatures
      } else {
        // Build default window features if none provided
        const featureParts = []
        if (windowSettings.width) featureParts.push(`width=${windowSettings.width}`)
        if (windowSettings.height) featureParts.push(`height=${windowSettings.height}`)
        features = featureParts.join(',')
      }

      window.open(url, targetName, features)
      return // Don't show the modal if we opened a window
    }

    // If no window settings or opening the window failed, fall back to modal
    setSettingsLaunchModalVisible(true)
  }

  return (
    <>
      <ExternalToolModalLauncher
        isOpen={settingsLaunchModalVisible}
        title={I18n.t('Modify settings for %{documentProcessingAppName}', {
          documentProcessingAppName: title,
        })}
        onRequestClose={() => setSettingsLaunchModalVisible(false)}
        iframeSrc={`/asset_processors/${assetProcessorId}/launch`}
        width={iframeSettings?.width}
        height={iframeSettings?.height}
      />
      <AssetProcessorsCard
        {...commonProps}
        extraColumns={
          <div style={{flex: 'none'}}>
            <AttachedAssetProcessorsMenu
              nameForScreenReader={title}
              onModify={isNil(assetProcessorId) ? undefined : onModify}
              modifyInNewWindow={modifyInNewWindow}
              onDelete={onDelete}
            />
          </div>
        }
      />
    </>
  )
}

export const AssetProcessorsCard = ({
  icon,
  title,
  description,
  children,
  onClick,
  extraColumns,
  margin,
}: AssetProcessorsCardProps) => (
  <View
    data-pendo="asset-processor-add-modal-tool"
    data-testid="asset-processor-card"
    aria-label={title}
    as="div"
    background="secondary"
    borderRadius="medium"
    borderWidth="none"
    {...(onClick ? {cursor: 'pointer'} : undefined)}
    margin={margin}
    onClick={onClick}
    padding="mediumSmall"
    position="relative"
    role={onClick ? 'button' : undefined}
    tabIndex={onClick ? 0 : undefined}
  >
    <Flex direction="column" height="100%">
      <Flex
        margin="0"
        {...{
          alignItems: description ? 'start' : undefined,
        }}
      >
        <div style={{borderRadius: '8px', overflow: 'hidden', flex: 'none'}}>
          <ToolIconOrDefault
            size={36}
            toolId={icon.toolId}
            margin={1}
            marginRight="1.4em"
            toolName={icon.toolName}
            iconUrl={icon.url}
          />
        </div>
        <div style={{overflow: 'hidden', flex: 1}}>
          <div style={{marginRight: '1.4em'}}>
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
          {description ? (
            <div style={{marginTop: '0.75em', marginRight: '1.4em'}}>
              <TruncateWithTooltip
                linesAllowed={4}
                horizontalOffset={0}
                backgroundColor="primary-inverse"
              >
                {description}
              </TruncateWithTooltip>
            </div>
          ) : null}
          {children}
        </div>
        {extraColumns}
      </Flex>
    </Flex>
  </View>
)
