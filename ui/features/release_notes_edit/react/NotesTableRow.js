/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import {
  IconPublishSolid,
  IconUnpublishedLine,
  IconMoreLine,
  IconEditLine,
  IconTrashLine,
} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {Table} from '@instructure/ui-table'
import {Menu} from '@instructure/ui-menu'
import {View} from '@instructure/ui-view'
import {rolesObject} from './util'

const I18n = useI18nScope('release_notes')

const formatLanguage = new Intl.DisplayNames(['en'], {type: 'language'})

export default function NotesTableRow({note, togglePublished, editNote, deleteNote}) {
  return (
    <Table.Row>
      <Table.Cell>{note.langs.en.title}</Table.Cell>
      <Table.Cell>{note.langs.en.description}</Table.Cell>
      <Table.Cell>{note.target_roles.map(role => rolesObject[role]).join(', ')}</Table.Cell>
      <Table.Cell>
        {Object.keys(note.langs)
          .map(lang => formatLanguage.of(lang))
          .join(', ')}
      </Table.Cell>
      <Table.Cell>
        <a href={note.langs.en.url}>{note.langs.en.url}</a>
      </Table.Cell>
      <Table.Cell>
        <IconButton
          screenReaderLabel={note.published ? I18n.t('Published') : I18n.t('Unpublished')}
          onClick={togglePublished}
          withBorder={false}
          withBackground={false}
        >
          {note.published ? <IconPublishSolid color="success" /> : <IconUnpublishedLine />}
        </IconButton>
      </Table.Cell>
      <Table.Cell>
        <Menu
          trigger={
            <IconButton
              screenReaderLabel={I18n.t('Menu')}
              withBorder={false}
              withBackground={false}
            >
              <IconMoreLine />
            </IconButton>
          }
        >
          <Menu.Item value="edit" onClick={() => editNote(note)}>
            <IconEditLine size="x-small" />
            <View padding="0 small">{I18n.t('Edit')}</View>
          </Menu.Item>
          <Menu.Item value="remove" onClick={() => deleteNote(note.id)}>
            <IconTrashLine size="x-small" />
            <View padding="0 small">{I18n.t('Remove')}</View>
          </Menu.Item>
        </Menu>
      </Table.Cell>
    </Table.Row>
  )
}

// Because instui requires that the children of the body element be a "Row" element...
NotesTableRow.displayName = 'Row'
