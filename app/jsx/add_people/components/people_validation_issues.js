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
import shapes from './shapes'
import DuplicateSection from './duplicate_section'
import MissingPeopleSection from './missing_people_section'
import Alert from '@instructure/ui-alerts/lib/components/Alert'

  class PeopleValidationIssues extends React.Component {
    static propTypes = {
      searchType: PropTypes.string.isRequired,
      inviteUsersURL: PropTypes.string,
      duplicates: PropTypes.shape(shapes.duplicatesShape),
      missing: PropTypes.shape(shapes.missingsShape),
      onChangeDuplicate: PropTypes.func.isRequired,
      onChangeMissing: PropTypes.func.isRequired
    };
    static defaultProps = {
      inviteUsersURL: undefined
    };

    static defaultProps = {
      duplicates: {},
      missing: {}
    };

    constructor (props) {
      super(props);

      this.state = {
        newUsersForMissing: {},
        focusElem: null
      }
    }
    componentDidUpdate () {
      if (this.state.focusElem) {
        this.state.focusElem.focus();
      }
    }


    // event handlers ------------------------------------
    // our user chose one from a set of duplicates
    // @param address: the address searched for that returned duplicate canvas users
    // @param user: the user data for the one selected
    onSelectDuplicate = (address, user) => {
      this.props.onChangeDuplicate({address, selectedUserId: user.user_id});
    }
    // our user chose to create a new canvas user rather than select one of the duplicate results
    // @param address: the address searched for that returned duplicate canvas users
    // @param newUserInfo: the new canvas user data entered by our user
    onNewForDuplicate = (address, newUserInfo) => {
      this.props.onChangeDuplicate({address, newUserInfo});
    }
    // our user chose to skip this searched for address
    // @param address: the address searched for that returned duplicate canvas users
    onSkipDuplicate = (address) => {
      this.props.onChangeDuplicate({address, skip: true});
    }
    // when the MissingPeopleSection changes,
    // it sends us the current list
    // @param address: the address searched for
    // @param newUserInfo: the new person user wants to invite, or false if skipping
    onNewForMissing = (address, newUserInfo) => {
      this.props.onChangeMissing({address, newUserInfo});
    }


    // rendering ------------------------------------
    // render the duplicates sections
    renderDuplicates () {
      const duplicateAddresses = this.props.duplicates && Object.keys(this.props.duplicates);
      if (!duplicateAddresses || duplicateAddresses.length === 0) {
        return null;
      }
      return (
        <div className="peopleValidationissues__duplicates">
          <Alert variant="warning">
            {I18n.t('There were several possible matches with the import. Please resolve them below.')}
          </Alert>
          {duplicateAddresses.map((address) => {
            const dupeSet = this.props.duplicates[address];
            return (
              <DuplicateSection
                key={`dupe_${address}`}
                inviteUsersURL={this.props.inviteUsersURL}
                duplicates={dupeSet}
                onSelectDuplicate={this.onSelectDuplicate}
                onNewForDuplicate={this.onNewForDuplicate}
                onSkipDuplicate={this.onSkipDuplicate}
              />
            )
          })}
        </div>
      );
    }
    // render the missing section
    renderMissing () {
      const missingAddresses = this.props.missing && Object.keys(this.props.missing);
      if (!missingAddresses || missingAddresses.length === 0) {
        return null;
      }
      const alertText = this.props.inviteUsersURL
        ? I18n.t('We were unable to find matches below. Select any you would like to create as new users. Unselected will be skipped at this time.')
        : I18n.t('We were unable to find matches below.');

      return (
        <div className="peoplevalidationissues__missing">
          <Alert variant="warning">{alertText}</Alert>
          <MissingPeopleSection
            inviteUsersURL={this.props.inviteUsersURL}
            missing={this.props.missing}
            searchType={this.props.searchType}
            onChange={this.onNewForMissing}
          />
        </div>
      );
    }
    render () {
      return (
        <div className="addpeople__peoplevalidationissues">
          {this.renderDuplicates()}
          {this.renderMissing()}
        </div>
      );
    }
  }

export default PeopleValidationIssues
