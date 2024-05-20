/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import PropTypes from 'prop-types'
import {View} from '@instructure/ui-view'
import {Menu} from '@instructure/ui-menu'
import {IconButton} from '@instructure/ui-buttons'
import {
  IconMoreLine,
  IconEditLine,
  IconXLine,
  IconMoveEndLine,
  IconInfoLine,
  IconSearchLine,
  IconImportLine,
  IconOutcomesLine,
  IconArchiveLine,
} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import {stripHtmlTags} from '@canvas/outcomes/stripHtmlTags'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'

const I18n = useI18nScope('OutcomeManagement')

const OutcomeKebabMenu = ({
  menuTitle,
  onMenuHandler,
  canEdit,
  canDestroy,
  isGroup,
  groupDescription,
  canArchive,
}) => {
  const {menuOptionForOutcomeDetailsPageFF, archiveOutcomesFF} = useCanvasContext()
  const hasDescription =
    typeof groupDescription === 'string' &&
    stripHtmlTags(groupDescription).replace(/[\n\r\t\s(&nbsp;)]+/g, '')
  return (
    <Menu
      trigger={
        <IconButton
          renderIcon={IconMoreLine}
          withBackground={false}
          withBorder={false}
          screenReaderLabel={menuTitle || I18n.t('Menu')}
        />
      }
      onSelect={onMenuHandler}
    >
      <Menu.Item disabled={!canEdit} value="edit">
        <IconEditLine size="x-small" />
        <View padding="0 x-large 0 small" data-testid="outcome-kebab-menu-edit">
          {I18n.t('Edit')}
        </View>
      </Menu.Item>
      {menuOptionForOutcomeDetailsPageFF && !isGroup && (
        <Menu.Item value="alignments">
          <IconOutcomesLine size="x-small" />
          <View padding="0 x-large 0 small" data-testid="outcome-kebab-menu-alignments">
            {I18n.t('Alignments')}
          </View>
        </Menu.Item>
      )}
      <Menu.Item value="move">
        <IconMoveEndLine size="x-small" />
        <View padding="0 x-large 0 small" data-testid="outcome-kebab-menu-move">
          {I18n.t('Move')}
        </View>
      </Menu.Item>
      {isGroup && (
        <Menu.Item value="add_outcomes">
          <IconSearchLine size="x-small" />
          <View padding="0 small">{I18n.t('Add Outcomes')}</View>
        </Menu.Item>
      )}
      {isGroup && (
        <Menu.Item value="import_outcomes">
          <IconImportLine size="x-small" />
          <View padding="0 small">{I18n.t('Import Outcomes')}</View>
        </Menu.Item>
      )}
      <Menu.Item disabled={!canDestroy} value="remove">
        <IconXLine size="x-small" />
        <View padding="0 small" data-testid="outcome-kebab-menu-remove">
          {I18n.t('Remove')}
        </View>
      </Menu.Item>
      {archiveOutcomesFF && (
        <Menu.Item disabled={isGroup ? false : !canArchive} value="archive">
          <IconArchiveLine size="x-small" />
          <View
            padding="0 small"
            data-testid={
              isGroup || canArchive
                ? 'outcome-kebab-menu-archive'
                : 'outcome-kebab-menu-archive-disabled'
            }
          >
            {I18n.t('Archive')}
          </View>
        </Menu.Item>
      )}
      {isGroup && <Menu.Separator />}
      {isGroup && (
        <Menu.Item value="description" disabled={!hasDescription}>
          <IconInfoLine size="x-small" />
          <View padding="0 small">{I18n.t('View Description')}</View>
        </Menu.Item>
      )}
    </Menu>
  )
}

OutcomeKebabMenu.propTypes = {
  onMenuHandler: PropTypes.func.isRequired,
  menuTitle: PropTypes.string,
  canDestroy: PropTypes.bool.isRequired,
  groupDescription: PropTypes.string,
  isGroup: PropTypes.bool,
  canEdit: PropTypes.bool,
  canArchive: PropTypes.bool,
}

OutcomeKebabMenu.defaultProps = {
  menuTitle: '',
  canEdit: true,
  isGroup: false,
  canArchive: false,
}

export default OutcomeKebabMenu
