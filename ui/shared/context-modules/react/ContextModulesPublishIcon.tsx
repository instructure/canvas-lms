/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import type {CanvasId} from './types'
import {IconMiniArrowDownLine, IconPublishSolid, IconUnpublishedLine} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {Menu} from '@instructure/ui-menu'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'

import {publishModule, unpublishModule} from '../utils/publishOneModuleHelper'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('context_modules_publish_icon')

interface Props {
  readonly courseId: CanvasId
  readonly moduleId: CanvasId
  readonly moduleName: string
  readonly published: boolean | undefined
  readonly isPublishing: boolean
  readonly loadingMessage?: string
}

// TODO: remove and replace MenuItem with Menu.Item below when on v8
const {Item: MenuItem} = Menu as any

const ContextModulesPublishIcon = ({
  courseId,
  moduleId,
  moduleName,
  published,
  isPublishing,
  loadingMessage,
}: Props) => {
  const statusIcon = () => {
    const iconStyles = {
      paddingLeft: '0.25rem',
    }
    if (isPublishing) {
      return <Spinner renderTitle={() => loadingMessage || I18n.t('working')} size="x-small" />
    } else if (published) {
      return (
        <>
          <IconPublishSolid size="x-small" color="success" style={iconStyles} />
          <IconMiniArrowDownLine size="x-small" />
        </>
      )
    } else {
      return (
        <>
          <IconUnpublishedLine size="x-small" color="secondary" style={iconStyles} />
          <IconMiniArrowDownLine size="x-small" />
        </>
      )
    }
  }

  const unpublishAll = () => {
    if (isPublishing) return
    unpublishModule(courseId, moduleId, false)
  }

  const publishAll = () => {
    if (isPublishing) return
    publishModule(courseId, moduleId, false)
  }

  const publishModuleOnly = () => {
    if (isPublishing) return
    publishModule(courseId, moduleId, true)
  }

  const unpublishModuleOnly = () => {
    if (isPublishing) return
    unpublishModule(courseId, moduleId, true)
  }

  const publishedStatus = published ? I18n.t('published') : I18n.t('unpublished')

  return (
    <View textAlign="center">
      <Menu
        placement="bottom"
        show={isPublishing ? false : undefined}
        trigger={
          <IconButton
            withBorder={false}
            screenReaderLabel={I18n.t('%{moduleName} module publish options, %{publishedStatus}', {
              moduleName,
              publishedStatus,
            })}
          >
            {statusIcon()}
          </IconButton>
        }
      >
        <MenuItem onClick={publishAll}>
          <IconPublishSolid color="success" /> {I18n.t('Publish module and all items')}
        </MenuItem>
        <MenuItem onClick={publishModuleOnly}>
          <IconPublishSolid color="success" /> {I18n.t('Publish module only')}
        </MenuItem>
        <MenuItem onClick={unpublishAll}>
          <IconUnpublishedLine /> {I18n.t('Unpublish module and all items')}
        </MenuItem>
        <MenuItem onClick={unpublishModuleOnly}>
          <IconUnpublishedLine /> {I18n.t('Unpublish module only')}
        </MenuItem>
      </Menu>
    </View>
  )
}

export default ContextModulesPublishIcon
