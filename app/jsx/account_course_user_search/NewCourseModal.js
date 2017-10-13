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
import {arrayOf} from 'prop-types'
import I18n from 'i18n!account_course_user_search'
import Modal from 'jsx/shared/modal'
import ModalContent from '../shared/modal-content'
import ModalButtons from '../shared/modal-buttons'
import CoursesStore from './CoursesStore'
import TermsStore from './TermsStore'
import AccountsTreeStore from './AccountsTreeStore'
import IcInput from './IcInput'
import IcSelect from './IcSelect'
import 'compiled/jquery.rails_flash_notifications'

export default class NewCourseModal extends React.Component {

  static propTypes = {
    terms: arrayOf(TermsStore.PropType),
    accounts: arrayOf(AccountsTreeStore.PropType)
  }

  constructor () {
    super()
    this.state = {
      isOpen: false,
      data: {},
      errors: {}
    }
  }

  openModal() {
    this.setState({ isOpen: true })
  }

  closeModal = () => {
    this.setState({ isOpen: false, data: {}, errors: {} })
  }

  onChange(field, value) {
    this.setState({
      data: {
        ...this.state.data,
        [field]: value
      },
      errors: {}
    })
  }

  onSubmit = () => {
    const { data } = this.state
    const errors = {}
    if (!data.name) errors.name = I18n.t('Course name is required')
    if (!data.course_code) errors.course_code = I18n.t('Reference code is required')
    if (Object.keys(errors).length) {
      this.setState({ errors })
      return
    }

    // TODO: error handling
    const promise = $.Deferred()
    CoursesStore.create({ course: data }).then(() => {
      this.closeModal()
      $.flashMessage(
        I18n.t('%{course_name} successfully added!', { course_name: data.name })
      )
      promise.resolve()
    })

    return promise
  }

  renderAccountOptions(accounts=this.props.accounts, depth=0) {
    return accounts.map(account =>
      [
        <option key={account.id} value={account.id}>
          {Array(2 * depth + 1).join('\u00a0') + account.name}
        </option>
      ].concat(
        this.renderAccountOptions(account.subAccounts || [], depth + 1)
      )
    )
  }

  renderTermOptions() {
    return (this.props.terms || []).map(term =>
      <option key={term.id} value={term.id}>
        {term.name}
      </option>
    )
  }

  render() {
    const { data, isOpen, errors } = this.state
    const onChange = field => e => this.onChange(field, e.target.value)

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
            className="name"
            label={I18n.t('Course Name')}
            value={data.name}
            error={errors.name}
            onChange={onChange('name')}
          />

          <IcInput
            className="course_code"
            label={I18n.t('Reference Code')}
            value={data.course_code}
            error={errors.course_code}
            onChange={onChange('course_code')}
          />

          <IcSelect
            className="account_id"
            label={I18n.t('Subaccount')}
            value={data.account_id}
            onChange={onChange('account_id')}
          >
            {this.renderAccountOptions()}
          </IcSelect>

          <IcSelect
            className="enrollment_term_id"
            label={I18n.t('Enrollment Term')}
            value={data.enrollment_term_id}
            onChange={onChange('enrollment_term_id')}
          >
            {this.renderTermOptions()}
          </IcSelect>
        </ModalContent>

        <ModalButtons>
          <button type="button" className="Button" onClick={this.closeModal}>
            {I18n.t('Cancel')}
          </button>

          <button type="submit" className="Button Button--primary">
            {I18n.t('Add Course')}
          </button>
        </ModalButtons>
      </Modal>
    )
  }
}
