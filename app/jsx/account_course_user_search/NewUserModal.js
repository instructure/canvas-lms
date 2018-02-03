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

import $ from 'jquery'
import React from 'react'
import PropTypes from 'prop-types'
import _ from 'underscore'
import I18n from 'i18n!account_course_user_search'
import {firstNameFirst, lastNameFirst, nameParts} from 'user_utils'
import Modal from '../shared/modal'
import ModalContent from '../shared/modal-content'
import ModalButtons from '../shared/modal-buttons'
import UsersStore from './UsersStore'
import IcInput from './IcInput'
import IcCheckbox from './IcCheckbox'
import 'compiled/jquery.rails_flash_notifications'

  const { object, string } = PropTypes

  var NewUserModal = React.createClass({

    propTypes: {
      userList: object.isRequired
    },

    getInitialState() {
      return {
        isOpen: false,
        data: {send_confirmation: true},
        errors: {}
      }
    },

    openModal() {
      this.setState({isOpen: true});
    },

    closeModal() {
      this.setState({isOpen: false, data: {}, errors: {}});
    },

    onChange(field, value) {
      var { data } = this.state;
      var newData = {};
      newData[field] = value;
      if (field === 'name') {
        // shamelessly copypasted from user_sortable_name.js
        var sortable_name_parts = nameParts(data.sortable_name);
        if ($.trim(data.sortable_name) == '' || firstNameFirst(sortable_name_parts) == $.trim(data.name)) {
          var parts = nameParts(value, sortable_name_parts[1]);
          newData.sortable_name = lastNameFirst(parts);
        }

        if ($.trim(data.short_name) == '' || data.short_name == data.name) {
          newData.short_name = value;
        }
      }
      data = _.extend({}, data, newData);
      this.setState({ data, errors: {} });
    },

    onSubmit() {
      var { data } = this.state;

      // Basic client side validation
      var errors = {}
      if (!data.name) errors.name = I18n.t("Full name is required");
      if (!data.email) errors.email = I18n.t("Email is required");
      if (Object.keys(errors).length) {
        return this.props.handlers.handleAddNewUserFormErrors(errors);
      }

      var url = `/accounts/${window.ENV.ACCOUNT_ID}/users`
      var params = {
        user: _.pick(data, 'name', 'short_name', 'sortable_name'),
        pseudonym: {
          unique_id: data.email,
          send_confirmation: data.send_confirmation
        }
      };

      this.props.handlers.handleAddNewUser(params)
      this.setState({
        isOpen: false
      });
    },

    render() {
      var { data, isOpen } = this.state;
      let {errors} = this.props.userList;
      var onChange = (field) => {
        return (e) => this.onChange(field, e.target.value);
      };

      return (
        <Modal
          className="ReactModal__Content--canvas ReactModal__Content--mini-modal"
          isOpen={isOpen}
          title={I18n.t('Add a New User')}
          contentLabel={I18n.t('Add a New User')}
          onRequestClose={this.closeModal}
          onSubmit={this.onSubmit}
        >
          <ModalContent>
            <IcInput
              className="user_name"
              label={I18n.t("Full Name")}
              value={data.name}
              error={errors.name}
              onChange={onChange("name")}
              hint={I18n.t("This name will be used by teachers for grading.")}
            />

            <IcInput
              className="user_short_name"
              label={I18n.t("Display Name")}
              value={data.short_name}
              error={errors.short_name}
              onChange={onChange("short_name")}
              hint={I18n.t("People will see this name in discussions, messages and comments.")}
            />

            <IcInput
              className="user_sortable_name"
              label={I18n.t("Sortable Name")}
              value={data.sortable_name}
              error={errors.sortable_name}
              onChange={onChange("sortable_name")}
              hint={I18n.t("This name appears in sorted lists.")}
            />

            <IcInput
              className="user_email"
              label={I18n.t("Email")}
              value={data.email}
              error={errors.email}
              onChange={onChange("email")}
            />

            <IcCheckbox
              className="user_send_confirmation"
              checked={data.send_confirmation}
              onChange={(e) => this.onChange('send_confirmation', e.target.checked)}
              label={I18n.t("Email the user about this account creation")}
            />

          </ModalContent>

          <ModalButtons>
            <button
              type="button"
              className="btn"
              onClick={this.closeModal}
            >
              {I18n.t("Cancel")}
            </button>

            <button
              type="submit"
              className="btn btn-primary"
            >
              {I18n.t("Add User")}
            </button>
          </ModalButtons>
        </Modal>
      );
    }
  });

export default NewUserModal
