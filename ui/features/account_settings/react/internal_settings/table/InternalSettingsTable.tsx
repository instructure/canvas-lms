// @ts-nocheck
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

import {Table} from '@instructure/ui-table'
import React, {useMemo, useState} from 'react'
import {InternalSetting} from '../types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {EditableCodeValue} from './EditableCodeValue'
import {InternalSettingActionButtons} from './InternalSettingActionButtons'
import {Menu} from '@instructure/ui-menu'
import exportFromJSON from 'export-from-json'
import {Link} from '@instructure/ui-link'

const I18n = useI18nScope('internal-settings')

// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
const {Body, ColHeader, Head, Row, RowHeader, Cell} = Table as any
const {Item} = Menu as any

// id, name, width, sortable
const tableHeaders: [string, string, string, boolean][] = [
  ['name', I18n.t('Name'), '45%', true],
  ['value', I18n.t('Value'), '40%', true],
  ['actions', I18n.t('Actions'), '15%', false],
]

export type InternalSettingsTableProps = {
  internalSettings: InternalSetting[]
  pendingChanges: {[id: string]: string}
  pendingNewInternalSetting?: {name?: string; value?: string}
  onValueChange: (id: string, newValue: string) => void
  onClearPendingChange: (id: string) => void
  onSubmitPendingChange: (id: string) => void
  onDelete: (id: string) => void
  onSetPendingNewInternalSetting: (internalSetting: {name?: string; value?: string}) => void
  onSubmitPendingNewInternalSetting: () => void
  onClearPendingNewInternalSetting: () => void
}

export const InternalSettingsTable = (props: InternalSettingsTableProps) => {
  const [sort, setSort] = useState<{ascending: boolean; sortBy: string}>({
    ascending: true,
    sortBy: 'name',
  })

  const handleSort = (_, {id}: {id: string}) => {
    if (id === sort.sortBy) {
      setSort({...sort, ascending: !sort.ascending})
    } else {
      setSort({
        sortBy: id,
        ascending: true,
      })
    }
  }

  const sortDirection = sort.ascending ? 'ascending' : 'descending'

  const sortedRows = useMemo(
    () =>
      [...props.internalSettings].sort((a, b) => {
        let [aVal, bVal] = [a[sort.sortBy], b[sort.sortBy]] as (string | null | undefined)[]

        if (aVal === null || aVal === undefined) {
          return sort.ascending ? -1 : 1
        } else if (bVal === null || bVal === undefined) {
          return sort.ascending ? 1 : -1
        }

        aVal = aVal.toLocaleLowerCase(window.navigator.language)
        bVal = bVal.toLocaleLowerCase(window.navigator.language)

        if (aVal < bVal) {
          return sort.ascending ? -1 : 1
        } else if (aVal > bVal) {
          return sort.ascending ? 1 : -1
        }

        return 0
      }),
    [sort.sortBy, sort.ascending, props.internalSettings]
  )

  // Don't export secret settings
  const exportableSettings = useMemo(
    () => props.internalSettings.filter(internalSetting => !internalSetting.secret),
    [props.internalSettings]
  )
  const exportParams = {data: exportableSettings, fileName: 'internal-settings'}

  return (
    <div>
      <div style={{display: 'flex', justifyContent: 'flex-end'}}>
        <Menu
          trigger={
            <Link isWithinText={false} as="button">
              <Text>{I18n.t('Download as...')}</Text>
            </Link>
          }
        >
          <Item onClick={() => exportFromJSON({...exportParams, exportType: 'json'})}>JSON</Item>
          <Item onClick={() => exportFromJSON({...exportParams, exportType: 'csv'})}>CSV</Item>
        </Menu>
      </div>
      <Table caption={I18n.t('Internal settings')} layout="fixed" margin="small auto">
        <Head renderSortLabel={I18n.t('Sort by')}>
          <Row>
            {tableHeaders.map(([id, name, width, sortable]) => (
              <ColHeader
                key={id}
                id={id}
                width={width}
                onRequestSort={sortable ? handleSort : undefined}
                sortDirection={id === sort.sortBy ? sortDirection : 'none'}
              >
                {name}
              </ColHeader>
            ))}
          </Row>
        </Head>
        <Body>
          {/* First row allows a new internal setting to be added */}
          <Row>
            <RowHeader>
              <EditableCodeValue
                value={props.pendingNewInternalSetting?.name || ''}
                onValueChange={name => props.onSetPendingNewInternalSetting({name})}
                screenReaderLabel={I18n.t('Edit new internal setting name')}
                placeholder={
                  !props.pendingNewInternalSetting?.name ? (
                    <Text color="secondary" weight="normal">
                      {I18n.t('New setting name...')}
                    </Text>
                  ) : undefined
                }
              />
            </RowHeader>
            <Cell>
              <EditableCodeValue
                value={props.pendingNewInternalSetting?.value || ''}
                onValueChange={value => props.onSetPendingNewInternalSetting({value})}
                screenReaderLabel={I18n.t('Edit new internal setting value')}
                placeholder={
                  !props.pendingNewInternalSetting?.value ? (
                    <Text color="secondary" weight="normal">
                      {I18n.t('New setting value...')}
                    </Text>
                  ) : undefined
                }
              />
            </Cell>
            <Cell>
              <InternalSettingActionButtons
                name={props.pendingNewInternalSetting?.name || ''}
                pendingChange={
                  !!(
                    props.pendingNewInternalSetting?.name && props.pendingNewInternalSetting?.value
                  )
                }
                onSubmitPendingChange={props.onSubmitPendingNewInternalSetting}
                onClearPendingChange={props.onClearPendingNewInternalSetting}
              />
            </Cell>
          </Row>
          {/* Rows for existing internal settings */}
          {sortedRows.map(internalSetting => (
            <Row key={internalSetting.id}>
              <RowHeader>
                <Text>
                  <code style={{wordBreak: 'break-word'}}>{internalSetting.name}</code>
                </Text>
              </RowHeader>
              <Cell>
                <EditableCodeValue
                  name={internalSetting.name}
                  value={props.pendingChanges[internalSetting.id] || internalSetting.value || ''}
                  secret={internalSetting.secret}
                  readonly={internalSetting.secret}
                  onValueChange={value => props.onValueChange(internalSetting.id, value)}
                />
              </Cell>
              <Cell>
                <InternalSettingActionButtons
                  name={internalSetting.name}
                  value={internalSetting.value || undefined}
                  secret={internalSetting.secret}
                  pendingChange={!!props.pendingChanges[internalSetting.id]}
                  onSubmitPendingChange={() => props.onSubmitPendingChange(internalSetting.id)}
                  onClearPendingChange={() => props.onClearPendingChange(internalSetting.id)}
                  onDelete={() => props.onDelete(internalSetting.id)}
                  allowCopy={true}
                />
              </Cell>
            </Row>
          ))}
        </Body>
      </Table>
    </div>
  )
}
