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
import {Link} from '@instructure/ui-link'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {TextInput} from '@instructure/ui-text-input'
import {propType as termsPropType} from '../store/TermsStore'
import SearchableSelect from './SearchableSelect'
import {useScope as createI18nScope} from '@canvas/i18n'
import CoursesStore from '../store/CoursesStore'
import AccountsTreeStore from '../store/AccountsTreeStore'
import {showFlashAlert, showFlashError} from '@canvas/alerts/react/FlashAlert'
import {flatten} from 'lodash'
import {clearDashboardCache} from '../../../../shared/dashboard-card/dashboardCardQueries'
import * as z from 'zod'
import {zodResolver} from '@hookform/resolvers/zod'
import {useForm, Controller} from 'react-hook-form'
import {getFormErrorMessage} from '@canvas/forms/react/react-hook-form/utils'
import {Term, Course} from '../../../../api'

type Account = {
  id: string
  name: string
  subAccounts: Account[]
}

type TermList = {
  data: Term[]
  loading: boolean
}

const I18n = createI18nScope('account_course_user_search')

const nonBreakingSpace = '\u00a0'

const renderAccountOptions = (accounts: Account[] = [], depth = 0): {id: string; name: string}[] =>
  flatten(
    accounts.map(account =>
      [{id: account.id, name: Array(2 * depth + 1).join(nonBreakingSpace) + account.name}].concat(
        renderAccountOptions(account.subAccounts || [], depth + 1),
      ),
    ),
  )

NewCourseModal.propTypes = {
  terms: termsPropType,
  children: node.isRequired,
}

const createValidationSchema = () =>
  z.object({
    name: z.string().min(1, I18n.t('Course name is required.')),
    reference_code: z.string().min(1, I18n.t('Reference code is required.')),
  })

export default function NewCourseModal({
  terms,
  children,
}: {terms: TermList; children: React.ReactNode}) {
  const [isOpen, setIsOpen] = useState(false)
  const [account, setAccount] = useState('')
  const [enrollmentTerm, setEnrollmentTerm] = useState('')
  const defaultValues = {name: '', reference_code: ''}
  const {
    formState: {errors},
    control,
    handleSubmit,
    setFocus,
  } = useForm({defaultValues, resolver: zodResolver(createValidationSchema())})

  const accountTree = AccountsTreeStore.getTree()

  function closeModal() {
    setIsOpen(false)
    setAccount('')
    setEnrollmentTerm('')
  }

  function onSubmit({name, reference_code}: typeof defaultValues) {
    const successHandler = (createdCourse: Course) => {
      closeModal()
      showFlashAlert({
        type: 'success',
        message: (
          <>
            {I18n.t('%{course_name} successfully added!', {course_name: createdCourse.name})}
            &emsp;
            <Link href={`/courses/${createdCourse.id}`}>{I18n.t('Go to the new course')}</Link>
          </>
        ),
      })
      if (window?.ENV?.FEATURES?.dashboard_graphql_integration) {
        clearDashboardCache()
      }
    }

    const errorHandler = () => {
      showFlashError(I18n.t('Something went wrong creating the course. Please try again.'))()
      setFocus('name')
    }

    const accountValue = account === '' ? undefined : account
    const enrollmentTermValue = enrollmentTerm === '' ? undefined : enrollmentTerm
    const data = {
      name: name,
      course_code: reference_code,
      account_id: accountValue,
      enrollment_term_id: enrollmentTermValue,
    }
    CoursesStore.create({course: data}, successHandler, errorHandler)
  }

  return (
    <span>
      <Modal
        noValidate={true}
        onSubmit={handleSubmit(onSubmit)}
        open={isOpen}
        onDismiss={closeModal}
        onOpen={() => AccountsTreeStore.loadTree()}
        size="small"
        label={I18n.t('Add a New Course')}
        shouldCloseOnDocumentClick={false}
      >
        <form style={{marginBottom: '0px'}}>
          <Modal.Body>
            <FormFieldGroup layout="stacked" rowSpacing="small" description="">
              <Controller
                name="name"
                control={control}
                render={({field}) => (
                  <TextInput
                    {...field}
                    data-testid="courseName"
                    renderLabel={I18n.t('Course Name')}
                    isRequired={true}
                    messages={getFormErrorMessage(errors, 'name')}
                  />
                )}
              />
              <Controller
                name="reference_code"
                control={control}
                render={({field}) => (
                  <TextInput
                    {...field}
                    data-testid="referenceCode"
                    renderLabel={I18n.t('Reference Code')}
                    isRequired={true}
                    messages={getFormErrorMessage(errors, 'reference_code')}
                  />
                )}
              />
              <SearchableSelect
                id="accountSelector"
                label={I18n.t('Subaccount')}
                isLoading={accountTree.loading}
                onChange={(_e, option) => setAccount(option.id)}
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
                onChange={(_e, option) => setEnrollmentTerm(option.id)}
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
            <Button data-testid="submitBtn" type="submit" color="primary">
              {I18n.t('Add Course')}
            </Button>
          </Modal.Footer>
        </form>
      </Modal>
      {React.Children.map(
        children,
        child =>
          React.isValidElement(child) &&
          // when you click whatever is the child element to this, open the modal
          React.cloneElement(child as React.ReactElement<any>, {
            onClick: () => {
              setIsOpen(true)
            },
          }),
      )}
    </span>
  )
}
