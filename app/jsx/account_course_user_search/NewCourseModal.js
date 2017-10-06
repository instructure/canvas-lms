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
import Modal from 'jsx/shared/modal'
import ModalContent from 'jsx/shared/modal-content'
import ModalButtons from 'jsx/shared/modal-buttons'
import CoursesStore from './CoursesStore'
import TermsStore from './TermsStore'
import AccountsTreeStore from './AccountsTreeStore'
import IcInput from './IcInput'
import IcSelect from './IcSelect'
import 'compiled/jquery.rails_flash_notifications'

  const { arrayOf, string } = PropTypes

  var NewCourseModal = React.createClass({
    propTypes: {
      terms: arrayOf(TermsStore.PropType),
      accounts: arrayOf(AccountsTreeStore.PropType)
    },

    getInitialState() {
      return {
        isOpen: false,
        data: {},
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
      data = _.extend({}, data, newData);
      this.setState({ data, errors: {} });
    },

    onSubmit() {
      var { data } = this.state;
      var errors = {}
      if (!data.name)        errors.name        = I18n.t("Course name is required");
      if (!data.course_code) errors.course_code = I18n.t("Reference code is required");
      if (Object.keys(errors).length) {
        this.setState({ errors });
        return;
      }

      // TODO: error handling
      var promise = $.Deferred();
      CoursesStore.create({course: data}).then(() => {
        this.closeModal();
        $.flashMessage(I18n.t("%{course_name} successfully added!", {course_name: data.name}));
        promise.resolve();
      });

      return promise;
    },

    renderAccountOptions(accounts, result, depth) {
      accounts = accounts || this.props.accounts;
      result = result || [];
      depth = depth || 0;

      accounts.forEach((account) => {
        result.push(
          <option key={account.id} value={account.id}>
            {Array(2 * depth + 1).join("\u00a0") + account.name}
          </option>
        );
        this.renderAccountOptions(account.subAccounts, result, depth + 1);
      });
      return result;
    },

    renderTermOptions() {
      var { terms } = this.props;
      return (terms || []).map((term) => {
        return (
          <option key={term.id} value={term.id}>
            {term.name}
          </option>
        );
      });
    },

    render() {
      var { data, isOpen, errors } = this.state;
      var onChange = (field) => {
        return (e) => this.onChange(field, e.target.value);
      };

      return (
        <Modal
          className="ReactModal__Content--canvas ReactModal__Content--mini-modal"
          isOpen={isOpen}
          title={I18n.t('Add a New Course')}
          onRequestClose={this.closeModal}
          onSubmit={this.onSubmit}
          contentLabel={I18n.t('Add a New Course')}
        >
          <ModalContent>
            <IcInput
              label={I18n.t("Course Name")}
              value={data.name}
              error={errors.name}
              onChange={onChange("name")}
            />

            <IcInput
              label={I18n.t("Reference Code")}
              value={data.course_code}
              error={errors.course_code}
              onChange={onChange("course_code")}
            />

            <IcSelect
              label={I18n.t("Subaccount")}
              value={data.account_id}
              onChange={onChange("account_id")}
            >
              {this.renderAccountOptions()}
            </IcSelect>

            <IcSelect
              label={I18n.t("Enrollment Term")}
              value={data.enrollment_term_id}
              onChange={onChange("account_id")}
            >
              {this.renderTermOptions()}
            </IcSelect>
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
              {I18n.t("Add Course")}
            </button>
          </ModalButtons>
        </Modal>
      );
    }
  });

export default NewCourseModal
