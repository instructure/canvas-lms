/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

/* eslint-disable no-console */
import React, {useState} from 'react'
import awaitElement from '@canvas/await-element'
import {renderCreateDialog, CreateOrEditSetModal} from './index'
import {Button} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {NumberInput} from '@instructure/ui-number-input'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {uniqueId} from 'lodash'

let reminder = false

export default {
  title: 'Examples/manage_groups/CreateOrEditSetModal',
  component: CreateOrEditSetModal,
}

let mockApiConfig = {}

function mockApi({path, body, method}) {
  method = method || 'GET'
  reminder = true

  if (method === 'POST' && path.match(/group_categories$/)) {
    if (mockApiConfig.failCreate)
      return Promise.reject(new Error('commanded groupset creation failure'))
    console.info(`=================== API CALL (create groupset) POST ${path}`)
    console.info(body)
    mockApiConfig.groupsCount = parseInt(body.create_group_count, 10)
    mockApiConfig.groupSetName = body.name
    mockApiConfig.groupsetId = uniqueId()
    const json = {
      id: mockApiConfig.groupsetId,
      name: mockApiConfig.groupSetName,
      groups_count: mockApiConfig.groupsCount,
    }
    return Promise.resolve({json})
  }

  const assignMatch = path.match(/(\d+)\/assign_unassigned_members$/)
  if (method === 'POST' && assignMatch) {
    const context_id = assignMatch[1]
    const id = uniqueId()
    const url = `/api/v1/progress/${id}`
    if (context_id !== mockApiConfig.groupsetId)
      return Promise.reject(
        new Error(`groupset id mismatch ${context_id} != ${mockApiConfig.groupsetId}`)
      )
    if (mockApiConfig.failAssign)
      return Promise.reject(new Error('commanded member assignment failure'))
    console.info(`=================== API CALL (assign members) POST ${path}`)
    const json = {
      context_type: 'GroupCategory',
      context_id,
      id,
      completion: 0,
      workflow_state: 'running',
      url,
    }
    mockApiConfig.jobId = id
    mockApiConfig.assignStart = new Date()
    mockApiConfig.progressUrl = url
    return Promise.resolve({json})
  }

  const progressMatch = path.match(/\/progress\/(\d+)$/)
  if (method === 'GET' && progressMatch) {
    const id = progressMatch[1]
    if (id !== mockApiConfig.jobId)
      return Promise.reject(new Error(`job id mismatch ${id} != ${mockApiConfig.jobId}`))
    console.info(`=================== API CALL (watch progress) GET ${path}`)
    const elapsed = new Date() - mockApiConfig.assignStart
    const completion = Math.min(100, Math.round(elapsed / 10 / mockApiConfig.assignTime))
    const workflow_state = completion === 100 ? 'complete' : 'running'
    const json = {
      id,
      context_type: 'GroupCategory',
      tag: 'assign_unassigned_members',
      url: mockApiConfig.progressUrl,
      context_id: mockApiConfig.groupsetId,
      completion,
      workflow_state,
    }
    return Promise.resolve({json})
  }

  const resultMatch = path.match(/^\/api\/v1\/group_categories\/(\d+)/)
  if (method === 'GET' && resultMatch) {
    const id = resultMatch[1]
    console.info(`=================== API CALL (get final result) GET ${path}`)
    const json = {
      id,
      groups_count: mockApiConfig.groupsCount,
      name: mockApiConfig.groupSetName,
      unassigned_users_count: 0,
    }
    return Promise.resolve({json})
  }

  return Promise.reject(new Error('Unexpected API call'))
}

const Wrapper = () => {
  const [modalIsOpen, setModalIsOpen] = useState(false)
  const [selfSignup, setSelfSignup] = useState(true)
  const [numSections, setNumSections] = useState(1)
  const [failCreate, setFailCreate] = useState(false)
  const [failAssign, setFailAssign] = useState(false)
  const [assignTime, setAssignTime] = useState(10)

  ENV = {
    allow_self_signup: selfSignup,
    student_section_count: numSections,
    context_asset_string: 'course_1',
  }

  function openModal() {
    if (modalIsOpen) return
    reminder = false
    setModalIsOpen(true)
    // eslint-disable-next-line promise/catch-or-return
    awaitElement('placeholder')
      .then(div => {
        mockApiConfig = {failCreate, failAssign, assignTime}
        return renderCreateDialog(div, mockApi)
      })
      .then(result => {
        console.info('FINAL PROMISE RESOLUTION FROM THE MODAL:')
        console.info(result)
      })
      .finally(() => {
        setModalIsOpen(false)
        mockApiConfig = {}
      })
  }

  function incrdecr(op, setter, step) {
    setter(value => {
      switch (op) {
        case '+':
          return value + step
        case '-':
          return value - (value <= step ? 0 : step)
      }
    })
  }

  return (
    <>
      <div id="flash_message_holder" role="alert" />
      <View as="div" padding="small medium" borderWidth="medium" borderColor="info">
        <FormFieldGroup description="Settings" layout="stacked">
          <Checkbox
            variant="toggle"
            label="Allow Self Signup"
            checked={selfSignup}
            onChange={e => setSelfSignup(e.target.checked)}
          />
          <Checkbox
            variant="toggle"
            label="Fail the creation API call"
            checked={failCreate}
            onChange={e => setFailCreate(e.target.checked)}
          />
          <Checkbox
            variant="toggle"
            label="Fail the assign-students API call"
            checked={failAssign}
            onChange={e => setFailAssign(e.target.checked)}
          />
          <div>
            <NumberInput
              renderLabel=""
              display="inline-block"
              size="small"
              width="5rem"
              value={numSections}
              onIncrement={incrdecr.bind(null, '+', setNumSections, 1)}
              onDecrement={incrdecr.bind(null, '-', setNumSections, 1)}
            />
            <View margin="none small">
              <Text>Section count</Text>
            </View>
          </div>
          <div>
            <NumberInput
              renderLabel=""
              display="inline-block"
              size="small"
              width="5rem"
              value={assignTime}
              onIncrement={incrdecr.bind(null, '+', setAssignTime, 5)}
              onDecrement={incrdecr.bind(null, '-', setAssignTime, 5)}
            />
            <View margin="none small">
              <Text>Assignment job takes this many seconds</Text>
            </View>
          </div>
        </FormFieldGroup>
      </View>
      <Button
        onClick={openModal}
        interaction={modalIsOpen ? 'disabled' : 'enabled'}
        color="primary"
        margin="medium none"
      >
        + Group Set
      </Button>
      {reminder && (
        <View as="div">
          <Text>Check the JS console to see what API calls the component makes.</Text>
        </View>
      )}

      <div id="placeholder" />
    </>
  )
}

const Template = args => <Wrapper {...args} />

export const Selector = Template.bind({})

Selector.args = {}
