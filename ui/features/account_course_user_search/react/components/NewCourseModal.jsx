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
import {node} from 'prop-types'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {Button} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {TextInput} from '@instructure/ui-text-input'
import {propType as termsPropType} from '../store/TermsStore'
import SearchableSelect from './SearchableSelect'
import {useScope as useI18nScope} from '@canvas/i18n'
import CoursesStore from '../store/CoursesStore'
import AccountsTreeStore from '../store/AccountsTreeStore'
import {showFlashAlert, showFlashError} from '@canvas/alerts/react/FlashAlert'
import preventDefault from '@canvas/util/preventDefault'
import {flatten} from 'lodash'

const I18n = useI18nScope('account_course_user_search')

const nonBreakingSpace = '\u00a0'
const renderAccountOptions = (accounts = [], depth = 0) =>
  flatten(
    accounts.map(account =>
      [{id: account.id, name: Array(2 * depth + 1).join(nonBreakingSpace) + account.name}].concat(
        renderAccountOptions(account.subAccounts || [], depth + 1)
      )
    )
  )

NewCourseModal.propTypes = {
  terms: termsPropType,
  children: node.isRequired,
}

const emptyData = {name: '', course_code: ''}

export default function NewCourseModal({terms, children}) {
  const [isOpen, setIsOpen] = useState(false)
  const [data, setData] = useState(emptyData)
  const [errors, setErrors] = useState({})

  const accountTree = AccountsTreeStore.getTree()

  function closeModal() {
    setIsOpen(false)
    setData(emptyData)
    setErrors({})
  }

  function onSubmit() {
    const errs = {}
    if (!data.name) errs.name = I18n.t('Course name is required')
    if (!data.course_code) errs.course_code = I18n.t('Reference code is required')
    if (Object.keys(errs).length > 0) {
      setErrors(errs)
      return
    }

    const successHandler = (createdCourse) => {
      closeModal()
      showFlashAlert({
        type: 'success',
        message: (
          <Text>
            {I18n.t('%{course_name} successfully added!', {course_name: createdCourse.name})}
            &emsp;
            <Link href={`/courses/${createdCourse.id}`}>{I18n.t('Go to the new course')}</Link>
          </Text>
        ),
      })
    }

    const errorHandler = showFlashError(I18n.t('Something went wrong creating the course. Please try again.'))

    CoursesStore.create({course: data}, successHandler, errorHandler)
  }

  function onChange(field) {
    return function (e, value) {
      setData(oldState => ({...oldState, [field]: value.id || value}))
      setErrors({})
    }
  }

  return (
    <span>
      <Modal
        as="form"
        onSubmit={preventDefault(onSubmit)}
        open={isOpen}
        onDismiss={closeModal}
        onOpen={() => AccountsTreeStore.loadTree()}
        size="small"
        label={I18n.t('Add a New Course')}
        shouldCloseOnDocumentClick={false}
      >
        <Modal.Body>
          <FormFieldGroup layout="stacked" rowSpacing="small" description="">
            <TextInput
              renderLabel={
                <>
                  {I18n.t('Course Name')}
                  <Text color="danger"> *</Text>
                </>
              }
              value={data.name}
              onChange={onChange('name')}
              isRequired={true}
              messages={errors.name && [{type: 'error', text: errors.name}]}
            />

            <TextInput
              renderLabel={
                <>
                  {I18n.t('Reference Code')}
                  <Text color="danger"> *</Text>
                </>
              }
              value={data.course_code}
              onChange={onChange('course_code')}
              isRequired={true}
              messages={errors.course_code && [{type: 'error', text: errors.course_code}]}
            />

            <SearchableSelect
              id="accountSelector"
              label={I18n.t('Subaccount')}
              isLoading={accountTree.loading}
              onChange={onChange('account_id')}
            >
              {renderAccountOptions(accountTree.accounts).map(account => (
                <SearchableSelect.Option key={account.id} id={account.id} value={account.id}>
                  {account.name}
                </SearchableSelect.Option>
              ))}
            </SearchableSelect>

            <SearchableSelect
              id="termSelector"
              label={I18n.t('Enrollment Term')}
              isLoading={terms.loading}
              onChange={onChange('enrollment_term_id')}
            >
              {(terms.data || []).map(term => (
                <SearchableSelect.Option key={term.id} id={term.id} value={term.id}>
                  {term.name}
                </SearchableSelect.Option>
              ))}
            </SearchableSelect>
          </FormFieldGroup>
        </Modal.Body>
        <Modal.Footer>
          <Button onClick={closeModal}>{I18n.t('Cancel')}</Button> &nbsp;
          <Button type="submit" color="primary">
            {I18n.t('Add Course')}
          </Button>
        </Modal.Footer>
      </Modal>
      {React.Children.map(children, child =>
        // when you click whatever is the child element to this, open the modal
        React.cloneElement(child, {
          onClick: (...args) => {
            if (child.props.onClick) child.props.onClick(...args)
            setIsOpen(true)
          },
        })
      )}
    </span>
  )
}
