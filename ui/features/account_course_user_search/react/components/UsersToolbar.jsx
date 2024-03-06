/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import React, {useState} from 'react'
import {bool, string, func, shape, arrayOf} from 'prop-types'
import {IconGroupLine, IconMoreLine, IconPlusLine, IconStudentViewLine} from '@instructure/ui-icons'
import {Button} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {Grid} from '@instructure/ui-grid'
import {Menu} from '@instructure/ui-menu'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextInput} from '@instructure/ui-text-input'
import CanvasSelect from '@canvas/instui-bindings/react/Select'
import {useScope as useI18nScope} from '@canvas/i18n'
import preventDefault from '@canvas/util/preventDefault'
import CreateOrUpdateUserModal from './CreateOrUpdateUserModal'

const I18n = useI18nScope('account_course_user_search')

export default function UsersToolbar(props) {
  const [recipientsFilterChecked, setRecipientFilterChecked] = useState(false)
  const [providersFilterChecked, setProvidersFilterChecked] = useState(false)
  const [includeDeletedUsers, setIncludeDeletedUsers] = useState(false)

  function handleRoleSelect(event, value) {
    props.onUpdateFilters({role_filter_id: value})
  }

  function handleTemporaryEnrollmentsFilterChange(filter, event) {
    if (filter === 'recipients') {
      setRecipientFilterChecked(event.target.checked)
      props.onUpdateFilters({
        temporary_enrollment_providers: providersFilterChecked,
        temporary_enrollment_recipients: event.target.checked,
      })
    } else if (filter === 'providers') {
      setProvidersFilterChecked(event.target.checked)

      props.onUpdateFilters({
        temporary_enrollment_recipients: recipientsFilterChecked,
        temporary_enrollment_providers: event.target.checked,
      })
    } else {
      throw new Error(`Unknown filter ${filter}`)
    }
  }

  const placeholder = I18n.t('Search people...')
  return (
    <form onSubmit={preventDefault(props.onApplyFilters)}>
      <Grid vAlign="top" startAt="medium">
        <Grid.Row>
          <Grid.Col>
            <Grid colSpacing="small" rowSpacing="small" startAt="large">
              <Grid.Row>
                <Grid.Col>
                  <CanvasSelect
                    id="userType"
                    label={
                      <ScreenReaderContent>{I18n.t('Filter by user type')}</ScreenReaderContent>
                    }
                    value={props.role_filter_id}
                    onChange={handleRoleSelect}
                  >
                    <CanvasSelect.Option key="all" id="all" value="">
                      {I18n.t('All Roles')}
                    </CanvasSelect.Option>
                    {props.roles.map(role => (
                      <CanvasSelect.Option key={role.id} id={role.id} value={role.id}>
                        {role.label}
                      </CanvasSelect.Option>
                    ))}
                  </CanvasSelect>
                </Grid.Col>
                <Grid.Col>
                  <TextInput
                    type="search"
                    value={props.search_term}
                    renderLabel={<ScreenReaderContent>{placeholder}</ScreenReaderContent>}
                    placeholder={placeholder}
                    onChange={e => props.onUpdateFilters({search_term: e.target.value})}
                    onKeyUp={e => {
                      if (e.key === 'Enter') {
                        props.toggleSRMessage(true)
                      } else {
                        props.toggleSRMessage(false)
                      }
                    }}
                    onBlur={() => props.toggleSRMessage(true)}
                    onFocus={() => props.toggleSRMessage(false)}
                    messages={
                      props.errors.search_term
                        ? [{type: 'error', text: props.errors.search_term}]
                        : []
                    }
                  />
                </Grid.Col>
                <Grid.Col>
                  {window.ENV.PERMISSIONS.can_create_users && (
                    <CreateOrUpdateUserModal
                      createOrUpdate="create"
                      url={`/accounts/${props.accountId}/users`}
                      afterSave={props.onApplyFilters} // update displayed results in case new user should appear
                    >
                      <Button aria-label={I18n.t('Add people')}>
                        <IconPlusLine />
                        {I18n.t('People')}
                      </Button>
                    </CreateOrUpdateUserModal>
                  )}{' '}
                  {renderKabobMenu(props.accountId)}
                </Grid.Col>
              </Grid.Row>
              {window.ENV.PERMISSIONS.can_view_temporary_enrollments && (
                <Grid.Row>
                  <Grid.Col width="auto">
                    <Checkbox
                      size="small"
                      checked={recipientsFilterChecked}
                      onChange={e => handleTemporaryEnrollmentsFilterChange('recipients', e)}
                      label={I18n.t('Show only temporary enrollment recipients')}
                    />
                  </Grid.Col>
                  <Grid.Col width="auto">
                    <Checkbox
                      size="small"
                      checked={providersFilterChecked}
                      onChange={e => handleTemporaryEnrollmentsFilterChange('providers', e)}
                      label={I18n.t('Show only temporary enrollment providers')}
                    />
                  </Grid.Col>
                </Grid.Row>
              )}
              {window.ENV.PERMISSIONS.can_edit_users && (
                <Grid.Row>
                  <Grid.Col width="auto">
                    <Checkbox
                      size="small"
                      checked={props.include_deleted_users}
                      onChange={e =>
                        // eslint-disable-next-line no-restricted-globals
                        props.onUpdateFilters({include_deleted_users: event.target.checked})
                      }
                      label={I18n.t('Include deleted users in search results')}
                    />
                  </Grid.Col>
                </Grid.Row>
              )}
            </Grid>
          </Grid.Col>
        </Grid.Row>
      </Grid>
    </form>
  )
}

function renderKabobMenu(accountId) {
  const newCourseAdminGranulars = ENV.FEATURES.granular_permissions_manage_users
  // see accounts_controller#avatars for the showAvatarItem logic
  const showAvatarItem = newCourseAdminGranulars
    ? ENV.PERMISSIONS.can_allow_course_admin_actions
    : ENV.PERMISSIONS.can_manage_admin_users
  const showGroupsItem = ENV.PERMISSIONS.can_manage_groups // see groups_controller#context_index
  if (showAvatarItem || showGroupsItem) {
    return (
      <Menu
        trigger={
          <Button renderIcon={IconMoreLine}>
            <ScreenReaderContent>{I18n.t('More People Options')}</ScreenReaderContent>
          </Button>
        }
      >
        {showAvatarItem && (
          <Menu.Item onClick={() => (window.location = `/accounts/${accountId}/avatars`)}>
            <IconStudentViewLine /> {I18n.t('Manage profile pictures')}
          </Menu.Item>
        )}
        {showGroupsItem && (
          <Menu.Item onClick={() => (window.location = `/accounts/${accountId}/groups`)}>
            <IconGroupLine /> {I18n.t('View user groups')}
          </Menu.Item>
        )}
      </Menu>
    )
  }
  return null
}

UsersToolbar.propTypes = {
  toggleSRMessage: func.isRequired,
  onUpdateFilters: func.isRequired,
  onApplyFilters: func.isRequired,
  search_term: string,
  include_deleted_users: bool,
  role_filter_id: string,
  errors: shape({search_term: string}),
  accountId: string,
  roles: arrayOf(
    shape({
      id: string.isRequired,
      label: string.isRequired,
    })
  ).isRequired,
}

UsersToolbar.defaultProps = {
  search_term: '',
  include_deleted_users: false,
  role_filter_id: '',
  errors: {},
  accountId: '',
  roles: [],
}
