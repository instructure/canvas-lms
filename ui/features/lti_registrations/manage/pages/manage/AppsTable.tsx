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

import * as tz from '@instructure/moment-utils'
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
import type {AppsSortDirection, AppsSortProperty} from '../../api/registrations'
import type {LtiRegistration} from '../../model/LtiRegistration'
import {useManageSearchParams, type ManageSearchParams} from './ManageSearchParams'
import {colors} from '@instructure/canvas-theme'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {Tooltip} from '@instructure/ui-tooltip'
import {Pagination} from '@instructure/ui-pagination'
import {MANAGE_APPS_PAGE_LIMIT} from './ManagePageLoadingState'

type CallbackWithRegistration = (registration: LtiRegistration) => void

export type AppsTableProps = {
  apps: PaginatedList<LtiRegistration>
  sort: AppsSortProperty
  dir: AppsSortDirection
  stale: boolean
  updateSearchParams: ReturnType<typeof useManageSearchParams>[1]
  deleteApp: CallbackWithRegistration
  page: number
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

const ellispsisStyles = {overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap'}

const Columns: ReadonlyArray<Column> = [
  {
    id: 'name',
    header: I18n.t('App Name'),
    width: '182px',
    sortable: true,
    render: r => (
      <Flex>
        {r.icon_url ? (
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
        ) : (
          <img
            alt={r.name}
            style={{height: 27, width: 27, marginRight: 12}}
            src={`/lti/tool_default_icon?id=${r.id}&name=${r.name}`}
          />
        )}
        <div style={ellispsisStyles} title={r.name}>
          {/* TODO: comment these in when we have a manage app screen */}
          {/* <Link to={`/manage/${r.id}`} as={RouterLink} isWithinText={false}> */}
          {r.name}
          {/* </Link> */}
        </div>
      </Flex>
    ),
  },
  {
    id: 'nickname',
    header: I18n.t('Nickname'),
    width: '220px',
    sortable: true,
    render: r =>
      r.admin_nickname ? (
        <div style={ellispsisStyles} title={r.admin_nickname}>
          {r.admin_nickname}
        </div>
      ) : null,
  },
  {
    id: 'lti_version',
    sortable: true,
    header: I18n.t('Version'),
    width: '90px',
    render: r => <div>{'legacy_configuration_id' in r ? '1.1' : '1.3'}</div>,
  },
  {
    id: 'installed',
    header: I18n.t('Installed On'),
    width: '132px',
    sortable: true,
    render: r => <div>{tz.format(r.created_at, 'date.formats.medium')}</div>,
  },
  {
    id: 'installed_by',
    header: I18n.t('Installed By'),
    width: '132px',
    sortable: true,
    render: r =>
      r.created_by ? (
        <div style={ellispsisStyles}>{r.created_by.short_name}</div>
      ) : (
        <div>
          <Tooltip renderTip={I18n.t('Historical data lacks records for "installed by."')}>
            <div style={{fontStyle: 'oblique'}}>{I18n.t('N/A')}</div>
          </Tooltip>
        </div>
      ),
  },
  {
    id: 'updated_by',
    header: I18n.t('Updated By'),
    width: '132px',
    sortable: true,
    render: r =>
      r.updated_by ? (
        <div style={ellispsisStyles}>{r.updated_by.short_name}</div>
      ) : (
        <div>
          <Tooltip renderTip={I18n.t('Historical data lacks records for "updated by."')}>
            <div style={{fontStyle: 'oblique'}}>{I18n.t('N/A')}</div>
          </Tooltip>
        </div>
      ),
  },
  {
    id: 'on',
    header: I18n.t('On/Off'),
    width: '96px',
    sortable: true,
    render: r => <div>{r.workflow_state === 'active' ? I18n.t('On') : I18n.t('Off')}</div>,
  },
  {
    id: 'actions',
    width: '80px',
    render: (r, {deleteApp}) => {
      const developer_key_id = r.developer_key_id
      return (
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
          {developer_key_id ? (
            <Menu.Item
              onClick={async () => {
                try {
                  await navigator.clipboard.writeText(developer_key_id)
                  showFlashAlert({
                    type: 'info',
                    message: I18n.t('Client ID copied'),
                  })
                } catch (error) {
                  showFlashAlert({
                    type: 'error',
                    message: I18n.t('There was an issue copying the client ID'),
                  })
                }
              }}
            >
              {I18n.t('Copy Client ID')}
            </Menu.Item>
          ) : null}
          <Menu.Item
            themeOverride={{
              labelColor: colors.textDanger,
              activeBackground: colors.backgroundDanger,
            }}
            onClick={() => deleteApp(r)}
          >
            {I18n.t('Delete App')}
          </Menu.Item>
        </Menu>
      )
    },
  },
]

const renderHeaderRow = (props: {
  sort: AppsSortProperty
  dir: AppsSortDirection
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
                const sort = val.id === 'installed' ? undefined : val.id
                props.updateSearchParams({
                  sort,
                  dir: val.id === props.sort && props.dir === 'desc' ? 'asc' : undefined,
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

export const AppsTable = (appsTableProps: AppsTableProps) => {
  const {apps, stale, ...restOfProps} = appsTableProps
  return (
    <div
      style={{
        opacity: stale ? '0.5' : '1',
      }}
    >
      {apps.data.length > 0 ? (
        <AppsTableResponsiveWrapper apps={apps} {...restOfProps} />
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

const AppsTableResponsiveWrapper = React.memo(
  (tableProps: Omit<AppsTableProps, 'stale' | 'pageCount' | 'updatePage'>) => {
    return (
      <Responsive query={ResponsiveQuery} props={ResponsiveProps}>
        {responsiveProps => (
          <AppsTableInner tableProps={tableProps} responsiveProps={responsiveProps} />
        )}
      </Responsive>
    )
  }
)

type AppsTableInnerProps = {
  responsiveProps: ResponsivePropsObject | null | undefined
  tableProps: Omit<AppsTableProps, 'stale' | 'pageCount' | 'updatePage'>
}

export const AppsTableInner = React.memo((props: AppsTableInnerProps) => {
  const [, setManageSearchParams] = useManageSearchParams()
  const responsiveProps = props.responsiveProps
  const {page, apps} = props.tableProps
  const rows = React.useMemo(() => {
    return props.tableProps.apps.data.map(row => (
      <Table.Row key={row.id}>
        {Columns.map(({id, render, textAlign}) => (
          <Table.Cell key={id} textAlign={textAlign}>
            {render(row, {deleteApp: props.tableProps.deleteApp})}
          </Table.Cell>
        ))}
      </Table.Row>
    ))
  }, [props.tableProps.apps, props.tableProps.deleteApp])

  const layout = responsiveProps && responsiveProps.layout === 'stacked' ? 'stacked' : 'fixed'

  return (
    <>
      <Table {...props.responsiveProps} caption={I18n.t('Installed Apps')} layout={layout}>
        <Table.Head renderSortLabel={I18n.t('Sort by')}>
          {renderHeaderRow(props.tableProps)}
        </Table.Head>
        <Table.Body>{rows}</Table.Body>
      </Table>

      <div
        style={{
          display: 'flex',
          flexDirection: 'row',
          justifyContent: layout === 'stacked' ? 'space-between' : 'center',
          width: '100%',
          alignItems: 'center',
        }}
      >
        <div style={{flex: layout === 'stacked' ? undefined : 1}}>
          {I18n.t('%{first_item} - %{last_item} of %{total_items} displayed', {
            first_item: (page - 1) * MANAGE_APPS_PAGE_LIMIT + 1,
            last_item: Math.min(page * MANAGE_APPS_PAGE_LIMIT, apps.total),
            total_items: apps.total,
          })}
        </div>
        <div style={{flex: layout === 'stacked' ? undefined : 1}}>
          <Pagination
            as="nav"
            margin="small"
            variant="compact"
            labelNext="Next Page"
            labelPrev="Previous Page"
          >
            {Array.from(Array(Math.ceil(apps.total / MANAGE_APPS_PAGE_LIMIT))).map((_, i) => (
              <Pagination.Page
                // eslint-disable-next-line react/no-array-index-key
                key={i}
                current={i === page - 1}
                onClick={() => {
                  setManageSearchParams({page: (i + 1).toString()})
                }}
              >
                {i + 1}
              </Pagination.Page>
            ))}
          </Pagination>
        </div>
        {layout === 'stacked' ? null : <div style={{flex: 1}} />}
      </div>
    </>
  )
})
