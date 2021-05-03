/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React, {useState, useCallback} from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!k5_dashboard_CreateCourseModal'

import {FormFieldGroup} from '@instructure/ui-form-field'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextInput} from '@instructure/ui-text-input'
import {Button} from '@instructure/ui-buttons'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'

import Modal from '@canvas/instui-bindings/react/InstuiModal'
import CanvasAsyncSelect from '@canvas/instui-bindings/react/AsyncSelect'
import useFetchApi from '@canvas/use-fetch-api-hook'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {createNewCourse, getAccountsFromEnrollments} from '@canvas/k5/react/utils'

export const CreateCourseModal = ({isModalOpen, setModalOpen, permissions}) => {
  const [loading, setLoading] = useState(true)
  const [allAccounts, setAllAccounts] = useState([])
  const [selectedAccount, setSelectedAccount] = useState(null)
  const [accountSearchTerm, setAccountSearchTerm] = useState('')
  const [courseName, setCourseName] = useState('')

  const clearModal = () => {
    setSelectedAccount(null)
    setAccountSearchTerm('')
    setCourseName('')
    setModalOpen(false)
  }

  const createCourse = () => {
    setLoading(true)
    createNewCourse(selectedAccount.id, courseName)
      .then(course => (window.location.href = `/courses/${course.id}/settings`))
      .catch(err => {
        setLoading(false)
        showFlashError(I18n.t('Error creating new course'))(err)
      })
  }

  const teacherFetchOpts = {
    path: '/api/v1/users/self/courses',
    success: useCallback(enrollments => {
      const accounts = getAccountsFromEnrollments(enrollments)
      setAllAccounts(accounts)
      if (accounts.length === 1) {
        setSelectedAccount(accounts[0])
        setAccountSearchTerm(accounts[0].name)
      }
    }, []),
    params: {
      per_page: 100,
      include: ['account']
    }
  }

  const adminFetchOpts = {
    path: '/api/v1/manageable_accounts',
    success: useCallback(accounts => {
      setAllAccounts(
        accounts.sort((a, b) => a.name.localeCompare(b.name, ENV.LOCALE, {sensitivity: 'base'}))
      )
    }, []),
    params: {
      per_page: 100
    }
  }

  useFetchApi({
    loading: setLoading,
    error: useCallback(err => showFlashError(I18n.t('Unable to get accounts'))(err), []),
    fetchAllPages: true,
    ...(permissions === 'teacher' ? teacherFetchOpts : adminFetchOpts)
  })

  const handleAccountSelected = id => {
    if (allAccounts != null) {
      const account = allAccounts.find(a => a.id === id)
      setSelectedAccount(account)
      setAccountSearchTerm(account.name)
    }
  }

  let accountOptions = []
  if (allAccounts) {
    accountOptions = allAccounts
      .filter(a => a.name.toLowerCase().includes(accountSearchTerm.toLowerCase()))
      .map(a => (
        <CanvasAsyncSelect.Option key={a.id} id={a.id} value={a.id}>
          {a.name}
        </CanvasAsyncSelect.Option>
      ))
  }

  // Don't show the account select for teachers with only one account to show
  const hideAccountSelect = permissions === 'teacher' && allAccounts?.length === 1

  return (
    <Modal label={I18n.t('Create Course')} open={isModalOpen} size="small" onDismiss={clearModal}>
      <Modal.Body>
        {loading ? (
          <View as="div" textAlign="center">
            <Spinner
              renderTitle={
                allAccounts.length
                  ? I18n.t('Creating new course...')
                  : I18n.t('Loading accounts...')
              }
            />
          </View>
        ) : (
          <FormFieldGroup
            description={<ScreenReaderContent>{I18n.t('Course Details')}</ScreenReaderContent>}
            layout="stacked"
            rowSpacing="medium"
          >
            {!hideAccountSelect && (
              <CanvasAsyncSelect
                inputValue={accountSearchTerm}
                renderLabel={I18n.t('Which account will this course be associated with?')}
                placeholder={I18n.t('Begin typing to search')}
                noOptionsLabel={I18n.t('No Results')}
                onInputChange={e => setAccountSearchTerm(e.target.value)}
                onOptionSelected={(_e, id) => handleAccountSelected(id)}
              >
                {accountOptions}
              </CanvasAsyncSelect>
            )}
            <TextInput
              renderLabel={I18n.t('Course Name')}
              placeholder={I18n.t('Name...')}
              value={courseName}
              onChange={e => setCourseName(e.target.value)}
            />
          </FormFieldGroup>
        )}
      </Modal.Body>
      <Modal.Footer>
        <Button
          color="secondary"
          onClick={clearModal}
          interaction={loading ? 'disabled' : 'enabled'}
        >
          {I18n.t('Cancel')}
        </Button>
        &nbsp;
        <Button
          color="primary"
          onClick={createCourse}
          interaction={
            courseName && !loading && selectedAccount?.name === accountSearchTerm
              ? 'enabled'
              : 'disabled'
          }
        >
          {I18n.t('Create')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

CreateCourseModal.propTypes = {
  isModalOpen: PropTypes.bool.isRequired,
  setModalOpen: PropTypes.func.isRequired,
  permissions: PropTypes.oneOf(['admin', 'teacher']).isRequired
}
