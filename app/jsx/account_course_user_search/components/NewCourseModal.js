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
import Modal from '../../shared/components/InstuiModal'
import {Button} from '@instructure/ui-buttons'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {TextInput} from '@instructure/ui-text-input'
import {propType as termsPropType} from '../store/TermsStore'
import SearchableSelect from './SearchableSelect'
import I18n from 'i18n!account_course_user_search'
import CoursesStore from '../store/CoursesStore'
import AccountsTreeStore from '../store/AccountsTreeStore'
import {showFlashAlert, showFlashError} from '../../shared/FlashAlert'
import preventDefault from 'compiled/fn/preventDefault'
import {flatten} from 'lodash'

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
  children: node.isRequired
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

    // CoursesStore.create doesn't return a Promise
    // eslint-disable-next-line promise/catch-or-return
    CoursesStore.create({course: data})
      .then(createdCourse => {
        closeModal()
        showFlashAlert({
          type: 'success',
          message: I18n.t('%{course_name} successfully added!', {course_name: createdCourse.name})
        })
      })
      .error(() => {
        showFlashError(I18n.t('Something went wrong creating the course. Please try again.'))
      })
  }

  function onChange(field) {
    return function(e, value) {
      setData(oldState => ({...oldState, [field]: value}))
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
              renderLabel={I18n.t('Course Name')}
              value={data.name}
              onChange={onChange('name')}
              isRequired
              messages={errors.name && [{type: 'error', text: errors.name}]}
            />

            <TextInput
              renderLabel={I18n.t('Reference Code')}
              value={data.course_code}
              onChange={onChange('course_code')}
              isRequired
              messages={errors.course_code && [{type: 'error', text: errors.course_code}]}
            />

            <SearchableSelect
              label={I18n.t('Subaccount')}
              options={renderAccountOptions(accountTree.accounts)}
              onChange={onChange('account_id')}
            />

            <SearchableSelect
              label={I18n.t('Enrollment Term')}
              options={terms.data || []}
              isLoading={terms.loading}
              onChange={onChange('enrollment_term_id')}
            />
          </FormFieldGroup>
        </Modal.Body>
        <Modal.Footer>
          <Button onClick={closeModal}>{I18n.t('Cancel')}</Button> &nbsp;
          <Button type="submit" variant="primary">
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
          }
        })
      )}
    </span>
  )
}
