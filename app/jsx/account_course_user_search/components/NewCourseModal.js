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

import React from 'react'
import {node} from 'prop-types'
import Button from '@instructure/ui-buttons/lib/components/Button'
import FormFieldGroup from '@instructure/ui-forms/lib/components/FormFieldGroup'
import TextInput from '@instructure/ui-forms/lib/components/TextInput'
import Select from '@instructure/ui-core/lib/components/Select'
import InstuiModal, {ModalBody, ModalFooter} from '../../shared/components/InstuiModal'

import I18n from 'i18n!account_course_user_search'
import preventDefault from 'compiled/fn/preventDefault'
import {showFlashAlert, showFlashError} from '../../shared/FlashAlert'

import CoursesStore from '../store/CoursesStore'
import {propType as termsPropType} from '../store/TermsStore'
import AccountsTreeStore from '../store/AccountsTreeStore'

const nonBreakingSpace = '\u00a0'
const renderAccountOptions = (accounts = [], depth = 0) =>
  accounts.map(account =>
    [
      <option key={account.id} value={account.id}>
        {Array(2 * depth + 1).join(nonBreakingSpace) + account.name}
      </option>
    ].concat(renderAccountOptions(account.subAccounts || [], depth + 1))
  )

export default class NewCourseModal extends React.Component {
  static propTypes = {
    terms: termsPropType,
    children: node.isRequired
  }

  state = {
    isOpen: false,
    data: {},
    errors: {}
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
    const {data} = this.state
    const errors = {}
    if (!data.name) errors.name = I18n.t('Course name is required')
    if (!data.course_code) errors.course_code = I18n.t('Reference code is required')
    if (Object.keys(errors).length) {
      this.setState({errors})
      return
    }

    CoursesStore.create({course: data}).then(createdCourse => {
      this.closeModal()
      showFlashAlert({
        type: 'success',
        message: I18n.t('%{course_name} successfully added!', {course_name: createdCourse.name})
      })
    }, showFlashError(I18n.t('Something went wrong creating course. Please try again.')))
  }

  closeModal = () => {
    this.setState({isOpen: false, data: {}, errors: {}})
  }

  render() {
    const {data, isOpen, errors} = this.state
    const {terms, children} = this.props
    const onChange = field => e => this.onChange(field, e.target.value)
    const accountTree = AccountsTreeStore.getTree()

    return (
      <span>
        <InstuiModal
          as="form"
          onSubmit={preventDefault(this.onSubmit)}
          open={isOpen}
          onDismiss={this.closeModal}
          onOpen={() => AccountsTreeStore.loadTree()}
          size="small"
          label={I18n.t('Add a New Course')}
        >
          <ModalBody>
            <FormFieldGroup layout="stacked" rowSpacing="small" description="">
              <TextInput
                label={I18n.t('Course Name')}
                value={data.name}
                onChange={onChange('name')}
                required
                messages={errors.name && [{type: 'error', text: errors.name}]}
              />

              <TextInput
                label={I18n.t('Reference Code')}
                value={data.course_code}
                onChange={onChange('course_code')}
                required
                messages={errors.course_code && [{type: 'error', text: errors.course_code}]}
              />

              <Select
                label={I18n.t('Subaccount')}
                value={data.account_id}
                onChange={onChange('account_id')}
              >
                {renderAccountOptions(accountTree.accounts)}
                {accountTree.loading && (
                  <option disabled>{I18n.t('Loading more sub accounts...')}</option>
                )}
              </Select>

              <Select
                label={I18n.t('Enrollment Term')}
                value={data.enrollment_term_id}
                onChange={onChange('enrollment_term_id')}
              >
                {(terms.data || []).map(term => (
                  <option key={term.id} value={term.id}>
                    {term.name}
                  </option>
                ))}
                {terms.loading && <option disabled>{I18n.t('Loading more terms...')}</option>}
              </Select>
            </FormFieldGroup>
          </ModalBody>
          <ModalFooter>
            <Button onClick={this.closeModal}>{I18n.t('Cancel')}</Button> &nbsp;
            <Button type="submit" variant="primary">
              {I18n.t('Add Course')}
            </Button>
          </ModalFooter>
        </InstuiModal>
        {React.Children.map(children, child =>
          // when you click whatever is the child element to this, open the modal
          React.cloneElement(child, {
            onClick: (...args) => {
              if (child.props.onClick) child.props.onClick(...args)
              this.setState({isOpen: true})
            }
          })
        )}
      </span>
    )
  }
}
