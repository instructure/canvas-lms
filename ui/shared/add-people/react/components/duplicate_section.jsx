/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import PropTypes from 'prop-types'
import {duplicateSetShape} from './shapes'
import {Text} from '@instructure/ui-text'
import {Table} from '@instructure/ui-table'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {RadioInput} from '@instructure/ui-radio-input'
import {TextInput} from '@instructure/ui-text-input'
import {Link} from '@instructure/ui-link'

const I18n = useI18nScope('add_people_duplicate_section')

const CREATE_NEW = '__CREATE_NEW__'
const SKIP = '__SKIP'
const nameLabel = I18n.t("New user's name")
const emailLabel = I18n.t('Required Email Address')

function eatEvent(event) {
  event.stopPropagation()
}

class DuplicateSection extends React.Component {
  static propTypes = {
    duplicates: PropTypes.shape(duplicateSetShape).isRequired,
    onSelectDuplicate: PropTypes.func.isRequired,
    onNewForDuplicate: PropTypes.func.isRequired,
    onSkipDuplicate: PropTypes.func.isRequired,
    inviteUsersURL: PropTypes.string,
  }

  static defaultProps = {
    inviteUsersURL: undefined,
  }

  // event handlers ----------------------------------------
  // user has selected a user from the list of duplicates
  onSelectDuplicate = event => {
    const userId = event.target.value
    const selectedUser = this.findUserById(userId)
    this.props.onSelectDuplicate(this.props.duplicates.address, selectedUser)
  }

  // user has chosen to create a new user for this group of duplicates
  // event comes either from the radio button or the adjacent link
  onSelectNewForDuplicate = event => {
    // if the event was not from the radio button, find and focus it
    if (!(event.target.tagName === 'input' && event.target.getAttribute('type') === 'radio')) {
      let elem = event.target
      for (; elem.tagName !== 'TR'; elem = elem.parentElement);
      const radioButton = elem.querySelector('input[type="radio"]')
      radioButton.focus()
    }
    this.props.onNewForDuplicate(this.props.duplicates.address, this.props.duplicates.newUserInfo)
  }

  // when either of the TextInputs for creating a new user from a duplicate list
  // changes, we come here to collect the input
  // @param field: the field of the new user we're providig (sice TextInput doesn't have a name attr)
  //                will be either "name" or "email"
  // @param event: the event that triggered the change
  onNewForDuplicateChange = event => {
    const field = event.target.getAttribute('name')
    const newUserInfo = this.props.duplicates.newUserInfo
    const newUser = {
      name: (newUserInfo && newUserInfo.name) || '',
      email: (newUserInfo && newUserInfo.email) || '',
    }
    newUser[field] = event.target.value
    this.props.onNewForDuplicate(this.props.duplicates.address, newUser, false)
  }

  // when the user chooses not to include any user from this set of duplicates
  onSkipDuplicate = () => {
    this.props.onSkipDuplicate(this.props.duplicates.address)
  }

  // helper ------------------------------------
  findUserById(userId) {
    let retval = null
    for (let i = 0; i < this.props.duplicates.userList.length; ++i) {
      const user = this.props.duplicates.userList[i]
      // match as string or number
      // eslint-disable-next-line eqeqeq
      if (user.user_id == userId) {
        retval = user
        break
      }
    }
    return retval
  }

  // rendering ------------------------------------
  // render all the users in props.duplicates
  // @returns array of table rows
  renderDupeList() {
    const duplicateSet = this.props.duplicates

    // first, render a row for each of the existing duplicate users
    const rows = duplicateSet.userList.map((dupe, i) => {
      const k = `dupe_${duplicateSet.address}_${i}`
      const checked = duplicateSet.selectedUserId === dupe.user_id
      return (
        <Table.Row key={k}>
          <Table.RowHeader>
            <RadioInput
              value={dupe.user_id}
              name={duplicateSet.address}
              onChange={this.onSelectDuplicate}
              checked={checked}
              label={
                <ScreenReaderContent>
                  {I18n.t('Click to select user %{name}', {name: dupe.user_name})}
                </ScreenReaderContent>
              }
            />
          </Table.RowHeader>
          <Table.Cell>{dupe.user_name}</Table.Cell>
          <Table.Cell>{dupe.email}</Table.Cell>
          <Table.Cell>{dupe.login_id}</Table.Cell>
          <Table.Cell>{dupe.sis_user_id || ''}</Table.Cell>
          <Table.Cell>{dupe.account_name || ''}</Table.Cell>
        </Table.Row>
      )
    })
    if (this.props.inviteUsersURL) {
      // next, add a row for creating a new user for this login id
      if (duplicateSet.createNew) {
        // render the row as an editor
        rows.push(
          <Table.Row key={duplicateSet.address + CREATE_NEW} data-testid="create-new">
            <Table.RowHeader>
              <RadioInput
                value={CREATE_NEW}
                name={duplicateSet.address}
                onChange={eatEvent}
                checked={true}
                label={
                  <ScreenReaderContent>
                    {I18n.t('Click to create a new user for %{address}', {
                      address: duplicateSet.address,
                    })}
                  </ScreenReaderContent>
                }
              />
            </Table.RowHeader>
            <Table.Cell>
              <TextInput
                isRequired={true}
                name="name"
                type="text"
                placeholder={nameLabel}
                renderLabel={<ScreenReaderContent>{nameLabel}</ScreenReaderContent>}
                value={duplicateSet.newUserInfo.name}
                onChange={this.onNewForDuplicateChange}
              />
            </Table.Cell>
            <Table.Cell>
              <TextInput
                isRequired={true}
                name="email"
                type="email"
                placeholder={emailLabel}
                renderLabel={<ScreenReaderContent>{emailLabel}</ScreenReaderContent>}
                value={duplicateSet.newUserInfo.email}
                onChange={this.onNewForDuplicateChange}
              />
            </Table.Cell>
            <Table.Cell colSpan="3" />
          </Table.Row>
        )
      } else {
        // render the row as a hint to the user
        rows.push(
          <Table.Row key={duplicateSet.address + CREATE_NEW} data-testid="create-new">
            <Table.RowHeader>
              <RadioInput
                value={CREATE_NEW}
                name={duplicateSet.address}
                onChange={this.onSelectNewForDuplicate}
                checked={false}
                label={
                  <ScreenReaderContent>
                    {I18n.t('Click to create a new user for %{login}', {
                      login: duplicateSet.address,
                    })}
                  </ScreenReaderContent>
                }
              />
            </Table.RowHeader>
            <Table.Cell colSpan="5">
              <Link
                isWithinText={false}
                as="button"
                onClick={this.onSelectNewForDuplicate}
                themeOverride={{mediumPaddingHorizontal: '0', mediumHeight: 'normal'}}
              >
                <Text>
                  {I18n.t('Create a new user for "%{address}"', {address: duplicateSet.address})}
                </Text>
              </Link>
            </Table.Cell>
          </Table.Row>
        )
      }
    }
    // finally, the skip this user row
    rows.push(
      <Table.Row key={duplicateSet.address + SKIP} data-testid="skip-addr">
        <Table.RowHeader>
          <RadioInput
            value={SKIP}
            name={duplicateSet.address}
            onChange={this.onSkipDuplicate}
            checked={duplicateSet.skip}
            label={
              <ScreenReaderContent>
                {I18n.t('Click to skip %{address}', {address: duplicateSet.address})}
              </ScreenReaderContent>
            }
          />
        </Table.RowHeader>
        <Table.Cell colSpan="5">
          <Link
            isWithinText={false}
            as="button"
            onClick={this.onSkipDuplicate}
            themeOverride={{mediumPaddingHorizontal: '0', mediumHeight: 'normal'}}
          >
            <Text>{I18n.t('Don’t add this user for now.')}</Text>
          </Link>
        </Table.Cell>
      </Table.Row>
    )
    return rows
  }

  render() {
    return (
      <div className="addpeople__duplicates namelist" key={`dupe_${this.props.duplicates.address}`}>
        <Table
          caption={
            <Text>
              {I18n.t(
                'Possible matches for "%{address}". Select the correct one below or create a new user.',
                {address: this.props.duplicates.address}
              )}
            </Text>
          }
        >
          <Table.Head>
            <Table.Row>
              <Table.ColHeader id="dupsection-select">
                <ScreenReaderContent>{I18n.t('User Selection')}</ScreenReaderContent>
              </Table.ColHeader>
              <Table.ColHeader id="dupsection-name">{I18n.t('Name')}</Table.ColHeader>
              <Table.ColHeader id="dupsection-email">{I18n.t('Email Address')}</Table.ColHeader>
              <Table.ColHeader id="dupsection-loginid">{I18n.t('Login ID')}</Table.ColHeader>
              <Table.ColHeader id="dupsection-sisid">{I18n.t('SIS ID')}</Table.ColHeader>
              <Table.ColHeader id="dupsection-inst">{I18n.t('Institution')}</Table.ColHeader>
            </Table.Row>
          </Table.Head>
          <Table.Body>{this.renderDupeList()}</Table.Body>
        </Table>
      </div>
    )
  }
}

export default DuplicateSection
