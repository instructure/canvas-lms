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
import {useScope as useI18nScope} from '@canvas/i18n'

import {FormFieldGroup} from '@instructure/ui-form-field'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextInput} from '@instructure/ui-text-input'
import {Button} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'

import Modal from '@canvas/instui-bindings/react/InstuiModal'
import CanvasAsyncSelect from '@canvas/instui-bindings/react/AsyncSelect'
import useFetchApi from '@canvas/use-fetch-api-hook'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {createNewCourse, getAccountsFromEnrollments} from './utils'

const I18n = useI18nScope('create_course_modal')

export const CreateCourseModal = ({
  isModalOpen,
  setModalOpen,
  permissions,
  restrictToMCCAccount,
  isK5User,
}) => {
  const [loading, setLoading] = useState(true)
  const [allAccounts, setAllAccounts] = useState([])
  const [allHomerooms, setAllHomerooms] = useState([])
  const [syncHomeroomEnrollments, setSyncHomeroomEnrollments] = useState(false)
  const [selectedHomeroom, setSelectedHomeroom] = useState(null)
  const [selectedAccount, setSelectedAccount] = useState(null)
  const [accountSearchTerm, setAccountSearchTerm] = useState('')
  const [courseName, setCourseName] = useState('')

  const errorMessage = isK5User
    ? I18n.t('Error creating new subject')
    : I18n.t('Error creating new course')
  const modalLabel = isK5User ? I18n.t('Create Subject') : I18n.t('Create Course')
  const loadingMessage = isK5User
    ? I18n.t('Creating new subject...')
    : I18n.t('Creating new course...')
  const courseNameLabel = isK5User ? I18n.t('Subject Name') : I18n.t('Course Name')
  const accountLabel = isK5User
    ? I18n.t('Which account will this subject be associated with?')
    : I18n.t('Which account will this course be associated with?')
  const formDescription = isK5User ? I18n.t('Subject Details') : I18n.t('Course Details')

  const clearModal = () => {
    setSelectedAccount(null)
    setSelectedHomeroom(null)
    setAccountSearchTerm('')
    setCourseName('')
    setModalOpen(false)
  }

  const createCourse = () => {
    setLoading(true)
    createNewCourse(selectedAccount.id, courseName, syncHomeroomEnrollments, selectedHomeroom?.id)
      .then(course => (window.location.href = `/courses/${course.id}/settings`))
      .catch(err => {
        setLoading(false)
        showFlashError(errorMessage)(err)
      })
  }

  const teacherStudentFetchOpts = {
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
      include: ['account'],
      // Show teachers only accounts where they have a teacher enrollment
      ...(permissions === 'teacher' && {enrollment_type: 'teacher'}),
    },
  }

  const adminFetchOpts = {
    path: '/api/v1/manageable_accounts',
    success: useCallback(accounts => {
      setAllAccounts(
        accounts.sort((a, b) => a.name.localeCompare(b.name, ENV.LOCALE, {sensitivity: 'base'}))
      )
    }, []),
    params: {
      per_page: 100,
    },
  }

  const noEnrollmentsFetchOpts = {
    path: '/api/v1/manually_created_courses_account',
    success: useCallback(account => {
      setAllAccounts(account)
      setSelectedAccount(account[0])
      setAccountSearchTerm(account[0].name)
    }, []),
  }

  let fetchOpts = {}

  if (window.ENV.FEATURES?.enhanced_course_creation_account_fetching) {
    fetchOpts = {
      path: '/api/v1/course_creation_accounts',
      // eslint-disable-next-line react-hooks/rules-of-hooks
      success: useCallback(accounts => {
        setAllAccounts(
          accounts.sort((a, b) => a.name.localeCompare(b.name, ENV.LOCALE, {sensitivity: 'base'}))
        )
      }, []),
      params: {
        per_page: 100,
      },
    }
  } else if (permissions === 'admin') {
    fetchOpts = adminFetchOpts
  } else if (permissions === 'no_enrollments') {
    fetchOpts = noEnrollmentsFetchOpts
  } else if (['teacher', 'student'].includes(permissions)) {
    fetchOpts = restrictToMCCAccount ? noEnrollmentsFetchOpts : teacherStudentFetchOpts
  }

  useFetchApi({
    loading: setLoading,
    error: useCallback(err => showFlashError(I18n.t('Unable to get accounts'))(err), []),
    fetchAllPages: true,
    ...fetchOpts,
  })

  const handleAccountSelected = id => {
    if (allAccounts != null) {
      const account = allAccounts.find(a => a.id === id)
      setSelectedAccount(account)
      setAccountSearchTerm(account.name)
      setSyncHomeroomEnrollments(false)
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

  const teacherHomeroomFetchOpts = {
    path: '/api/v1/users/self/courses',
  }

  const adminHomeroomFetchOpts = {
    path: selectedAccount
      ? `api/v1/accounts/${selectedAccount.id}/courses`
      : '/api/v1/users/self/courses',
  }

  useFetchApi({
    loading: setLoading,
    success: useCallback(courses => {
      const homerooms = courses ? courses.filter(homeroom => homeroom.homeroom_course) : []
      setAllHomerooms(homerooms)
      if (homerooms.length > 0) {
        setSelectedHomeroom(homerooms[0])
      } else {
        setSelectedHomeroom(null)
      }
    }, []),
    params: {
      homeroom: true,
      per_page: 100,
    },
    error: useCallback(err => showFlashError(I18n.t('Unable to get homerooms'))(err), []),
    fetchAllPages: true,
    // don't let students/users with no enrollments sync homeroom data
    forceResult: ['no_enrollments', 'student'].includes(permissions) ? [] : undefined,
    ...(permissions === 'teacher' && teacherHomeroomFetchOpts),
    ...(permissions === 'admin' && adminHomeroomFetchOpts),
  })

  const handleHomeroomSelected = id => {
    if (allHomerooms != null) {
      const homeroom = allHomerooms.find(a => a.id === id)
      setSelectedHomeroom(homeroom)
    }
  }

  const handleSyncEnrollmentsChanged = e => {
    setSyncHomeroomEnrollments(e.target.checked)
    if (e.target.checked && homeroomOptions[0]) {
      handleHomeroomSelected(homeroomOptions[0].props?.id)
    }
  }

  let homeroomOptions = []
  if (selectedAccount) {
    homeroomOptions = allHomerooms
      .filter(homeroom => homeroom.account_id === selectedAccount.id)
      .map(homeroom => (
        <SimpleSelect.Option id={homeroom.id} key={`opt-${homeroom.id}`} value={homeroom.id}>
          {homeroom.name}
        </SimpleSelect.Option>
      ))
  }

  // Don't show the account select for non-admins with only one account to show
  const hideAccountSelect = permissions !== 'admin' && allAccounts?.length === 1
  // Don't show homeroom sync to non-k5 users or to students/users with no enrollments
  const showHomeroomSyncOptions = isK5User && ['admin', 'teacher'].includes(permissions)

  return (
    <Modal label={modalLabel} open={isModalOpen} size="small" onDismiss={clearModal}>
      <Modal.Body>
        {loading ? (
          <View as="div" textAlign="center">
            <Spinner
              renderTitle={allAccounts.length ? loadingMessage : I18n.t('Loading accounts...')}
            />
          </View>
        ) : (
          <FormFieldGroup
            description={<ScreenReaderContent>{formDescription}</ScreenReaderContent>}
            layout="stacked"
            rowSpacing="medium"
          >
            {!hideAccountSelect && (
              <CanvasAsyncSelect
                inputValue={accountSearchTerm}
                renderLabel={accountLabel}
                placeholder={I18n.t('Begin typing to search')}
                noOptionsLabel={I18n.t('No Results')}
                onInputChange={e => setAccountSearchTerm(e.target.value)}
                onOptionSelected={(_e, id) => handleAccountSelected(id)}
              >
                {accountOptions}
              </CanvasAsyncSelect>
            )}
            {showHomeroomSyncOptions && (
              <Checkbox
                label={I18n.t('Sync enrollments and subject start/end dates from homeroom')}
                value="syncHomeroomEnrollments"
                checked={syncHomeroomEnrollments}
                onChange={handleSyncEnrollmentsChanged}
              />
            )}
            {showHomeroomSyncOptions && syncHomeroomEnrollments && (
              <SimpleSelect
                data-testid="homeroom-select"
                renderLabel={I18n.t('Select a homeroom')}
                assistiveText={I18n.t('Use arrow keys to navigate options.')}
                onChange={(_e, data) => handleHomeroomSelected(data.id)}
              >
                {homeroomOptions}
              </SimpleSelect>
            )}
            <TextInput
              renderLabel={courseNameLabel}
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
  permissions: PropTypes.oneOf(['admin', 'teacher', 'student', 'no_enrollments']).isRequired,
  restrictToMCCAccount: PropTypes.bool.isRequired,
  isK5User: PropTypes.bool.isRequired,
}
