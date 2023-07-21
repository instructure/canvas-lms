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
import {Table} from '@instructure/ui-table'

import NotesTableRow from './NotesTableRow'

const I18n = useI18nScope('release_notes')

export default function NotesTable({notes, setPublished, editNote, deleteNote}) {
  return (
    <Table margin="small 0" caption={I18n.t('Release Notes')}>
      <Table.Head>
        <Table.Row>
          <Table.ColHeader id="en_title">{I18n.t('Title')}</Table.ColHeader>
          <Table.ColHeader id="en_description">{I18n.t('Description')}</Table.ColHeader>
          <Table.ColHeader id="roles">{I18n.t('Available to')}</Table.ColHeader>
          <Table.ColHeader id="langs">{I18n.t('Languages')}</Table.ColHeader>
          <Table.ColHeader id="en_url">{I18n.t('Link URL')}</Table.ColHeader>
          <Table.ColHeader id="published">{I18n.t('Published')}</Table.ColHeader>
          <Table.ColHeader id="empty">{/* Empty so the menu column looks right */}</Table.ColHeader>
        </Table.Row>
      </Table.Head>
      <Table.Body>
        {notes.map(note => (
          <NotesTableRow
            note={note}
            togglePublished={() => setPublished(note.id, !note.published)}
            editNote={editNote}
            deleteNote={deleteNote}
            key={note.id}
          />
        ))}
      </Table.Body>
    </Table>
  )
}
