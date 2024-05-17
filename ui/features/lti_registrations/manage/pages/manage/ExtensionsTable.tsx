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

import * as tz from '@instructure/datetime'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Alert} from '@instructure/ui-alerts'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconMoreLine, IconSearchLine} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {Menu} from '@instructure/ui-menu'
import {Responsive, type ResponsivePropsObject} from '@instructure/ui-responsive'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import React from 'react'
import {Link as RouterLink} from 'react-router-dom'
import type {PaginatedList} from '../../api/PaginatedList'
import type {ExtensionsSortDirection, ExtensionsSortProperty} from '../../api/registrations'
import type {LtiRegistration} from '../../model/LtiRegistration'
import {useManageSearchParams, type ManageSearchParams} from './ManageSearchParams'
import {colors} from '@instructure/canvas-theme'

type CallbackWithRegistration = (registration: LtiRegistration) => void

export type ExtensionsTableProps = {
  extensions: PaginatedList<LtiRegistration>
  sort: ExtensionsSortProperty
  dir: ExtensionsSortDirection
  stale: boolean
  updateSearchParams: ReturnType<typeof useManageSearchParams>[1]
  deleteApp: CallbackWithRegistration
}

const I18n = useI18nScope('lti_registrations')

type Column = {
  id: string
  header?: string
  width: string
  textAlign?: 'start' | 'center' | 'end'
  sortable?: boolean
  render: (
    registration: LtiRegistration,
    callbacks: {deleteApp: CallbackWithRegistration}
  ) => React.ReactNode
}

const Columns: ReadonlyArray<Column> = [
  {
    id: 'name',
    header: I18n.t('Extension Name'),
    width: '26%',
    sortable: true,
    render: r => (
      <Flex>
        <img
          alt={r.name}
          style={{
            height: 27,
            width: 27,
            marginRight: 12,
            borderRadius: '4.5px',
            border: '0.75px solid #C7CDD1',
          }}
          src={r.icon_url}
        />
        <div style={{overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap'}}>
          <Link to={`/manage/${r.id}`} as={RouterLink} isWithinText={false}>
            {r.name}
          </Link>
        </div>
      </Flex>
    ),
  },
  {
    id: 'nickname',
    header: I18n.t('Nickname'),
    width: '20.64%',
    sortable: true,
    render: r => (
      <div style={{overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap'}}>
        {r.admin_nickname}
      </div>
    ),
  },
  {
    id: 'lti_version',
    sortable: true,
    header: I18n.t('Version'),
    width: '8.44%',
    render: r => <div>{'legacy_configuration_id' in r ? '1.1' : '1.3'}</div>,
  },
  {
    id: 'installed',
    header: I18n.t('Installed On'),
    width: '14.5%',
    sortable: true,
    render: r => <div>{tz.format(r.created_at, 'date.formats.medium')}</div>,
  },
  {
    id: 'installed_by',
    header: I18n.t('Installed By'),
    width: '16.98%',
    sortable: true,
    render: r => <div>{r.created_by}</div>,
  },
  {
    id: 'on',
    header: I18n.t('On/Off'),
    width: '8.44%',
    sortable: true,
    render: r => <div>{r.workflow_state === 'active' ? I18n.t('On') : I18n.t('Off')}</div>,
  },
  {
    id: 'actions',
    width: '62px',
    render: (r, {deleteApp}) => (
      <Menu
        trigger={
          <IconButton
            withBackground={false}
            withBorder={false}
            screenReaderLabel={I18n.t('More Registration Options')}
          >
            <IconMoreLine />
          </IconButton>
        }
      >
        <Menu.Item
          themeOverride={{labelColor: colors.textDanger, activeBackground: colors.backgroundDanger}}
          onClick={() => deleteApp(r)}
        >
          {I18n.t('Delete App')}
        </Menu.Item>
      </Menu>
    ),
  },
]

const renderHeaderRow = (props: {
  sort: ExtensionsSortProperty
  dir: ExtensionsSortDirection
  updateSearchParams: (
    params: Partial<Record<keyof ManageSearchParams, string | undefined>>
  ) => void
}) => (
  <Table.Row>
    {Columns.map(({id, header, width, textAlign, sortable}) => (
      <Table.ColHeader
        key={id}
        id={id}
        width={width}
        textAlign={textAlign}
        {...(sortable
          ? {
              stackedSortByLabel: header,
              onRequestSort: (_e, val) => {
                // this removes parameters if they are the default (name for sort, and asc for dir)
                const sort = val.id === 'name' ? undefined : val.id
                props.updateSearchParams({
                  sort,
                  dir: val.id === props.sort && props.dir === 'asc' ? 'desc' : undefined,
                  page: undefined,
                })
              },
              sortDirection:
                id === props.sort ? (props.dir === 'asc' ? 'ascending' : 'descending') : 'none',
            }
          : {})}
      >
        {header}
      </Table.ColHeader>
    ))}
  </Table.Row>
)

export const ExtensionsTable = (extensionsTableProps: ExtensionsTableProps) => {
  const {extensions, stale, ...restOfProps} = extensionsTableProps
  return (
    <div
      style={{
        opacity: stale ? '0.5' : '1',
      }}
    >
      {extensions.data.length > 0 ? (
        <ExtensionsTableResponsiveWrapper extensions={extensions} {...restOfProps} />
      ) : (
        <Flex direction="column" alignItems="center" padding="large 0">
          <IconSearchLine size="medium" color="secondary" />
          <View margin="small 0 0">
            <Text size="large">{I18n.t(`No results found`)}</Text>
          </View>
          <Alert
            liveRegion={() => document.getElementById('flash_screenreader_holder') as HTMLElement}
            liveRegionPoliteness="assertive"
            screenReaderOnly={true}
          >
            {I18n.t(`No results found`)}
          </Alert>
        </Flex>
      )}
    </div>
  )
}

const ResponsiveQuery = {
  small: {maxWidth: '40rem'},
  large: {minWidth: '41rem'},
}

const ResponsiveProps = {
  small: {layout: 'stacked'},
  large: {layout: 'auto'},
}

const ExtensionsTableResponsiveWrapper = React.memo(
  (tableProps: Omit<ExtensionsTableProps, 'stale' | 'page' | 'pageCount' | 'updatePage'>) => {
    return (
      <Responsive query={ResponsiveQuery} props={ResponsiveProps}>
        {responsiveProps => (
          <ExtensionsTableInner tableProps={tableProps} responsiveProps={responsiveProps} />
        )}
      </Responsive>
    )
  }
)

type ExtensionsTableInnerProps = {
  responsiveProps: ResponsivePropsObject | null | undefined
  tableProps: Omit<ExtensionsTableProps, 'stale' | 'page' | 'pageCount' | 'updatePage'>
}

export const ExtensionsTableInner = React.memo((props: ExtensionsTableInnerProps) => {
  const rows = React.useMemo(() => {
    return props.tableProps.extensions.data.map(row => (
      <Table.Row key={row.id}>
        {Columns.map(({id, render, textAlign}) => (
          <Table.Cell key={id} textAlign={textAlign}>
            {render(row, {deleteApp: props.tableProps.deleteApp})}
          </Table.Cell>
        ))}
      </Table.Row>
    ))
  }, [props.tableProps.extensions, props.tableProps.deleteApp])

  return (
    <>
      <Table
        {...props.responsiveProps}
        caption={I18n.t('Installed Extensions')}
        layout={
          props.responsiveProps && props.responsiveProps.layout === 'stacked' ? 'stacked' : 'fixed'
        }
      >
        <Table.Head renderSortLabel={I18n.t('Sort by')}>
          {renderHeaderRow(props.tableProps)}
        </Table.Head>
        <Table.Body>{rows}</Table.Body>
      </Table>
    </>
  )
})
