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
import {personReadyToEnrollShape} from './shapes'
import {Alert} from '@instructure/ui-alerts'
import {Table} from '@instructure/ui-table'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = useI18nScope('PeopleReadyList')

class PeopleReadyList extends React.Component {
  static propTypes = {
    nameList: PropTypes.arrayOf(PropTypes.shape(personReadyToEnrollShape)),
    defaultInstitutionName: PropTypes.string,
    canReadSIS: PropTypes.bool,
  }

  static defaultProps = {
    nameList: [],
    defaultInstitutionName: '',
    canReadSIS: true,
  }

  renderNotice() {
    return this.props.nameList.length > 0 ? (
      <Alert variant="success">
        {I18n.t('The following users are ready to be added to the course.')}
      </Alert>
    ) : (
      <Alert variant="info">{I18n.t('No users were selected to add to the course')}</Alert>
    )
  }

  renderUserTable() {
    let userTable = null
    if (this.props.nameList.length > 0) {
      userTable = (
        <Table caption={<ScreenReaderContent>{I18n.t('User list')}</ScreenReaderContent>}>
          <Table.Head>
            <Table.Row>
              <Table.ColHeader id="usertable-name">{I18n.t('Name')}</Table.ColHeader>
              <Table.ColHeader id="usertable-email">{I18n.t('Email Address')}</Table.ColHeader>
              <Table.ColHeader id="usertable-loginid">{I18n.t('Login ID')}</Table.ColHeader>
              {this.props.canReadSIS ? (
                <Table.ColHeader id="usertable-sisid">{I18n.t('SIS ID')}</Table.ColHeader>
              ) : null}
              <Table.ColHeader id="usertable-inst">{I18n.t('Institution')}</Table.ColHeader>
            </Table.Row>
          </Table.Head>
          <Table.Body>
            {this.props.nameList.map(n => (
              <Table.Row key={n.address}>
                <Table.RowHeader>{n.user_name}</Table.RowHeader>
                <Table.Cell>{n.email}</Table.Cell>
                <Table.Cell>{n.login_id || ''}</Table.Cell>
                {this.props.canReadSIS ? <Table.Cell>{n.sis_user_id || ''}</Table.Cell> : null}
                <Table.Cell>{n.account_name || this.props.defaultInstitutionName}</Table.Cell>
              </Table.Row>
            ))}
          </Table.Body>
        </Table>
      )
    }
    return userTable
  }

  render() {
    return (
      <div className="addpeople__peoplereadylist">
        <div className="peoplereadylist__pad-box">{this.renderNotice()}</div>
        {this.renderUserTable()}
      </div>
    )
  }
}

export default PeopleReadyList
