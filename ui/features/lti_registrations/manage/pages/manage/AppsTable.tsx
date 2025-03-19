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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Alert} from '@instructure/ui-alerts'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconMoreLine, IconSearchLine} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {Responsive, type ResponsivePropsObject} from '@instructure/ui-responsive'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Link} from '@instructure/ui-link'
import {Link as RouterLink} from 'react-router-dom'
import React from 'react'
import type {PaginatedList} from '../../api/PaginatedList'
import type {AppsSortDirection, AppsSortProperty} from '../../api/registrations'
import {isForcedOn, type LtiRegistration} from '../../model/LtiRegistration'
import {useManageSearchParams, type ManageSearchParams} from './ManageSearchParams'
import {colors} from '@instructure/canvas-theme'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {Tooltip} from '@instructure/ui-tooltip'
import {Pagination} from '@instructure/ui-pagination'
import {MANAGE_APPS_PAGE_LIMIT, refreshRegistrations} from './ManagePageLoadingState'
import {
  openEditDynamicRegistrationWizard,
  openEditManualRegistrationWizard,
} from '../../registration_wizard/RegistrationWizardModalState'
import {alert} from '@canvas/instui-bindings/react/Alert'
import {ToolIconOrDefault} from '@canvas/lti-apps/components/common/ToolIconOrDefault'

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

const I18n = createI18nScope('lti_registrations')

type Column = {
  id: string
  header?: string
  width: string
  textAlign?: 'start' | 'center' | 'end'
  sortable?: boolean
  render: (
    registration: LtiRegistration,
    callbacks: {deleteApp: CallbackWithRegistration},
  ) => React.ReactNode
}

const ellipsisStyles = {overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap'}

const renderEditButton = (r: LtiRegistration) => {
  const imsRegistrationId = r.ims_registration_id
  const manualConfigurationId = r.manual_configuration_id
  if (r.inherited) {
    return null
  } else if (imsRegistrationId) {
    return (
      <Menu.Item
        onClick={() => {
          openEditDynamicRegistrationWizard(r.id, refreshRegistrations)
        }}
      >
        {I18n.t('Edit App')}
      </Menu.Item>
    )
  } else if (manualConfigurationId && !r.inherited) {
    return (
      <Menu.Item
        onClick={() => {
          openEditManualRegistrationWizard(r.id, refreshRegistrations)
        }}
      >
        {I18n.t('Edit App')}
      </Menu.Item>
    )
  } else {
    return null
  }
}

const DangerMenuItemThemeOverrides = {
  labelColor: colors.contrasts.red4570,
  activeBackground: colors.contrasts.red4570,
}

const Columns: ReadonlyArray<Column> = [
  {
    id: 'name',
    header: I18n.t('App Name'),
    width: '150px',
    sortable: true,
    render: r => {
      const appName = (
        <Flex>
          <ToolIconOrDefault
            iconUrl={r.icon_url}
            toolId={r.id}
            toolName={r.name}
            size={27}
            marginRight={12}
          />
          <div style={ellipsisStyles} title={r.name}>
            {r.name}
          </div>
        </Flex>
      )
      return window.ENV.FEATURES.lti_registrations_next ? (
        <Link
          as={RouterLink}
          to={`/manage/${r.id}/configuration`}
          isWithinText={false}
          data-testid={`reg-link-${r.id}`}
        >
          {appName}
        </Link>
      ) : (
        appName
      )
    },
  },
  {
    id: 'nickname',
    header: I18n.t('Nickname'),
    width: '160px',
    sortable: true,
    render: r =>
      r.admin_nickname ? (
        <div style={ellipsisStyles} title={r.admin_nickname}>
          {r.admin_nickname}
        </div>
      ) : null,
  },
  {
    id: 'lti_version',
    sortable: true,
    header: I18n.t('Version'),
    width: '80px',
    render: r => <div>{'legacy_configuration_id' in r ? '1.1' : '1.3'}</div>,
  },
  {
    id: 'installed_by',
    header: I18n.t('Installed By'),
    width: '132px',
    sortable: true,
    render: r => {
      if (r.created_by === 'Instructure') {
        return <div style={ellipsisStyles}>{I18n.t('Instructure')}</div>
      } else if (r.created_by) {
        return <div style={ellipsisStyles}>{r.created_by.short_name}</div>
      } else {
        return (
          <div>
            <Tooltip renderTip={I18n.t('Historical data lacks records for "installed by."')}>
              <div style={{fontStyle: 'oblique', textAlign: 'center'}}>{I18n.t('N/A')}</div>
            </Tooltip>
          </div>
        )
      }
    },
  },
  {
    id: 'installed',
    header: I18n.t('Installed On'),
    width: '130px',
    sortable: true,
    render: r => <div>{tz.format(r.created_at, 'date.formats.medium')}</div>,
  },
  {
    id: 'updated_by',
    header: I18n.t('Updated By'),
    width: '132px',
    sortable: true,
    render: r => {
      if (r.updated_by === 'Instructure') {
        return <div style={ellipsisStyles}>{I18n.t('Instructure')}</div>
      } else if (r.updated_by) {
        return <div style={ellipsisStyles}>{r.updated_by.short_name}</div>
      } else {
        return (
          <div>
            <Tooltip renderTip={I18n.t('Historical data lacks records for "updated by."')}>
              <div style={{fontStyle: 'oblique', textAlign: 'center'}}>{I18n.t('N/A')}</div>
            </Tooltip>
          </div>
        )
      }
    },
  },
  {
    id: 'updated',
    header: I18n.t('Updated On'),
    width: '130px',
    sortable: true,
    render: r => <div>{tz.format(r.updated_at, 'date.formats.medium')}</div>,
  },
  {
    id: 'on',
    header: I18n.t('On/Off'),
    width: '80px',
    sortable: true,
    render: r => (
      <div>{r.account_binding?.workflow_state === 'on' ? I18n.t('On') : I18n.t('Off')}</div>
    ),
  },
  {
    id: 'actions',
    width: '60px',
    render: (r, {deleteApp}) => {
      const developerKeyId = r.developer_key_id

      return (
        <Menu
          data-testid={`actions-menu-${r.id}`}
          trigger={
            <IconButton
              data-testid={`actions-menu-${r.id}`}
              withBackground={false}
              withBorder={false}
              screenReaderLabel={I18n.t('More Registration Options')}
            >
              <IconMoreLine />
            </IconButton>
          }
        >
          {developerKeyId ? (
            <Menu.Item
              onClick={async () => {
                try {
                  await navigator.clipboard.writeText(developerKeyId)
                  showFlashAlert({
                    type: 'info',
                    message: I18n.t('Client ID copied (%{id})', {id: developerKeyId}),
                  })
                } catch {
                  showFlashAlert({
                    type: 'error',
                    message: I18n.t('There was an issue copying the client ID (%{id})', {
                      id: developerKeyId,
                    }),
                  })
                }
              }}
            >
              {I18n.t('Copy Client ID')}
            </Menu.Item>
          ) : null}
          {!window.ENV.FEATURES.lti_registrations_next ? renderEditButton(r) : null}
          {!window.ENV.FEATURES.lti_registrations_next ? (
            isForcedOn(r) ? (
              <Menu.Item
                themeOverride={DangerMenuItemThemeOverrides}
                onClick={() => {
                  alert({
                    message: I18n.t('This App is locked on, and cannot be deleted.'),
                    title: I18n.t('Delete App'),
                    okButtonLabel: I18n.t('Ok'),
                  })
                }}
              >
                {I18n.t('Delete App')}
              </Menu.Item>
            ) : (
              <Menu.Item themeOverride={DangerMenuItemThemeOverrides} onClick={() => deleteApp(r)}>
                {I18n.t('Delete App')}
              </Menu.Item>
            )
          ) : null}

          {/* <Menu.Item
            onClick={() => {
              confirm({
                message: JSON.stringify(r, null, 2),
                title: I18n.t('Registration Details'),
              })
            }}
          >
            Details
          </Menu.Item> */}
        </Menu>
      )
    },
  },
]

const renderHeaderRow = (props: {
  sort: AppsSortProperty
  dir: AppsSortDirection
  updateSearchParams: (
    params: Partial<Record<keyof ManageSearchParams, string | undefined>>,
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
  },
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
