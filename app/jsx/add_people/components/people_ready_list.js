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

import I18n from 'i18n!roster'
import React from 'react'
import PropTypes from 'prop-types'
import {personReadyToEnrollShape} from './shapes'
import Alert from '@instructure/ui-core/lib/components/Alert'
import Table from '@instructure/ui-core/lib/components/Table'
import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent'

  class PeopleReadyList extends React.Component {
    static propTypes = {
      nameList: PropTypes.arrayOf(PropTypes.shape(personReadyToEnrollShape)),
      defaultInstitutionName: PropTypes.string,
      canReadSIS: PropTypes.bool
    };
    static defaultProps = {
      nameList: [],
      defaultInstitutionName: '',
      canReadSIS: true
    };

    renderNotice () {
      return (
        this.props.nameList.length > 0
          ? <Alert variant="success">{I18n.t('The following users are ready to be added to the course.')}</Alert>
          : <Alert variant="info">{I18n.t('No users were selected to add to the course')}</Alert>
      );
    }
    renderUserTable () {
      let userTable = null;
      if (this.props.nameList.length > 0) {
        userTable = (
          <Table caption={<ScreenReaderContent>{I18n.t('User list')}</ScreenReaderContent>}>
            <thead>
              <tr>
                <th>{I18n.t('Name')}</th>
                <th>{I18n.t('Email Address')}</th>
                <th>{I18n.t('Login ID')}</th>
                {this.props.canReadSIS ? <th>{I18n.t('SIS ID')}</th> : null}
                <th>{I18n.t('Institution')}</th>
              </tr>
            </thead>
            <tbody>
              {this.props.nameList.map((n, i) => (
                <tr key={`${n.address}_${i}`}>
                  <th scope="row">{n.user_name}</th>
                  <td>{n.email}</td>
                  <td>{n.login_id || ''}</td>
                  {this.props.canReadSIS ? <td>{n.sis_user_id || ''}</td> : null}
                  <td>{n.account_name || this.props.defaultInstitutionName}</td>
                </tr>
              ))}
            </tbody>
          </Table>
        );
      }
      return userTable;
    }

    render () {
      return (
        <div className="addpeople__peoplereadylist">
          <div className="peoplereadylist__pad-box">
            {this.renderNotice()}
          </div>
          {this.renderUserTable()}
        </div>
      );
    }
  }

export default PeopleReadyList
