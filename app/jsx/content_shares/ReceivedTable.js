/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {arrayOf, func} from 'prop-types'
import I18n from 'i18n!content_share'
import {Table} from '@instructure/ui-table'
import {Menu} from '@instructure/ui-menu'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import {Button} from '@instructure/ui-buttons'
import {IconMoreLine, IconEyeLine, IconImportLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-layout'
import FriendlyDatetime from 'jsx/shared/FriendlyDatetime'
import {Avatar, Badge, Text} from '@instructure/ui-elements'
import contentShareShape from 'jsx/shared/proptypes/contentShare'

ReceivedTable.propTypes = {
  shares: arrayOf(contentShareShape),
  onPreview: func,
  onImport: func
}

export default function ReceivedTable({shares, onPreview, onImport}) {
  function renderActionMenu(share) {
    return (
      <Menu
        data-testid="action-menu"
        trigger={
          <Button variant="icon" size="small" icon={IconMoreLine}>
            <ScreenReaderContent>
              {I18n.t('Manage options for %{name}', {name: share.name})}
            </ScreenReaderContent>
          </Button>
        }
      >
        <Menu.Item data-testid="preview-menu-action" onSelect={() => onPreview(share)}>
          <IconEyeLine /> <View margin="0 0 0 x-small">{I18n.t('Preview')}</View>
        </Menu.Item>
        <Menu.Item data-testid="import-menu-action" onSelect={() => onImport(share)}>
          <IconImportLine /> <View margin="0 0 0 x-small">{I18n.t('Import')}</View>
        </Menu.Item>
      </Menu>
    )
  }

  function renderUnreadBadge(state) {
    if (state !== 'read')
      return (
        <div data-testid="received-table-row-unread">
          <Badge margin="0 0 xxx-small 0" standalone type="notification" />
          <ScreenReaderContent>{I18n.t('unread')}</ScreenReaderContent>
        </div>
      )
    else return <ScreenReaderContent>{I18n.t('read')}</ScreenReaderContent>
  }

  function renderRow(share) {
    return (
      <Table.Row key={share.id}>
        <Table.Cell textAlign="end">{renderUnreadBadge(share.read_state)}</Table.Cell>
        <Table.Cell>{share.name}</Table.Cell>
        <Table.Cell>
          <Text transform="capitalize">{share.content_type}</Text>
        </Table.Cell>
        <Table.Cell>
          <Avatar
            margin="0 small 0 0"
            size="small"
            name={share.sender.display_name}
            src={share.sender.avatar_image_url}
          />{' '}
          {share.sender.display_name}
        </Table.Cell>
        <Table.Cell>
          <FriendlyDatetime dateTime={share.created_at} />
        </Table.Cell>
        <Table.Cell>{renderActionMenu(share)}</Table.Cell>
      </Table.Row>
    )
  }

  return (
    <Table caption={I18n.t('Content shared by others to you')} layout="auto" hover>
      <Table.Head>
        <Table.Row>
          <Table.ColHeader id="unread">
            <ScreenReaderContent>{I18n.t('Status')}</ScreenReaderContent>
          </Table.ColHeader>
          <Table.ColHeader id="title">{I18n.t('Title')}</Table.ColHeader>
          <Table.ColHeader id="type">{I18n.t('Type')}</Table.ColHeader>
          <Table.ColHeader id="from">{I18n.t('From')}</Table.ColHeader>
          <Table.ColHeader id="received">{I18n.t('Received')}</Table.ColHeader>
          <Table.ColHeader id="actions">{I18n.t('Actions')}</Table.ColHeader>
        </Table.Row>
      </Table.Head>
      <Table.Body>{shares.map(share => renderRow(share))}</Table.Body>
    </Table>
  )
}
