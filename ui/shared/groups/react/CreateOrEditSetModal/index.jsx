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

import React, {useEffect, useRef, useReducer} from 'react'
import ReactDOM from 'react-dom'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Spinner} from '@instructure/ui-spinner'
import {bool, func, number, string} from 'prop-types'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {GroupContext, SPLIT, API_STATE, stateToContext} from './context'

import {GroupSetName} from './GroupSetName'
import {SelfSignup} from './SelfSignup'
import {GroupStructure} from './GroupStructure'
import {Leadership} from './Leadership'
import {AssignmentProgress} from './AssignmentProgress'
import doFetchApi from '@canvas/do-fetch-api-effect'

const I18n = useI18nScope('groups')

const INITIAL_STATE = Object.freeze({
  name: '',
  selfSignup: false,
  bySection: false,
  splitGroups: '0',
  createGroupCount: '0',
  groupLimit: '',
  createGroupMemberCount: '0',
  enableAutoLeader: false,
  autoLeaderType: 'FIRST',
  apiState: API_STATE.inactive,
  errors: {},
})

function reducer(prevState, action) {
  switch (action.ev) {
    case 'reset':
      return INITIAL_STATE
    case 'error': {
      const errors = {...prevState.errors}
      if (action.name) errors.name = action.name
      if (action.structure) errors.structure = action.structure
      return {...prevState, errors}
    }
    case 'api-change':
      return {...prevState, apiState: API_STATE[action.to]}
    case 'name-change': {
      const errors = {...prevState.errors}
      delete errors.name
      return {...prevState, errors, name: action.to}
    }
    case 'structure-change': {
      const {createGroupCount, createGroupMemberCount, groupLimit, splitGroups, bySection} =
        action.to
      const errors = {...prevState.errors}
      delete errors.structure
      return {
        ...prevState,
        errors,
        createGroupCount,
        createGroupMemberCount,
        groupLimit,
        splitGroups,
        bySection,
      }
    }
    case 'selfsignup-change': {
      const {selfSignup, bySection} = action.to
      return {...prevState, selfSignup, bySection: selfSignup ? bySection : false}
    }
    case 'leadership-change': {
      const {enableAutoLeader, autoLeaderType} = action.to
      return {
        ...prevState,
        enableAutoLeader,
        autoLeaderType: enableAutoLeader ? autoLeaderType : 'FIRST',
      }
    }
    default:
      throw new RangeError('bad event passed to dispatcher')
  }
}

const ASYNC_ACTIVE_STATES = ['queued', 'running']

const modalLabel = () => I18n.t('Create Group Set')

const Divider = () => (
  <View as="div" margin="medium none">
    <hr style={{border: 'none', borderBottom: '1px dotted #aaa'}} />
  </View>
)

export const CreateOrEditSetModal = ({
  closed,
  onDismiss,
  studentSectionCount,
  context,
  contextId,
  allowSelfSignup,
  mockApi, // used for Storybook only
}) => {
  const [st, dispatch] = useReducer(reducer, INITIAL_STATE)
  const topElement = useRef(null)
  const creationJSON = useRef(undefined)
  const areErrors = Object.keys(st.errors).length > 0
  const apiCall = mockApi || doFetchApi
  const isApiActive = st.apiState !== API_STATE.inactive
  const isApiAssigning = st.apiState === API_STATE.assigning && creationJSON.current

  function buildPayload() {
    if (!allowSelfSignup) return {name: st.name}

    const parms = {
      name: st.name,
      group_limit: st.groupLimit,
      enable_self_signup: st.selfSignup ? '1' : '0',
      enable_auto_leader: st.enableAutoLeader ? '1' : '0',
      create_group_count: st.createGroupCount,
    }
    parms[st.selfSignup ? 'restrict_self_signup' : 'group_by_section'] = st.bySection ? '1' : '0'
    if (st.splitGroups !== SPLIT.off) parms.assign_async = true
    if (st.enableAutoLeader) parms.auto_leader_type = st.autoLeaderType
    if (!st.selfSignup) {
      parms.create_group_member_count = st.createGroupMemberCount
      parms.split_groups = st.splitGroups
    }
    return parms
  }

  function resetValues() {
    if (!closed) dispatch({ev: 'reset'})
  }

  useEffect(resetValues, [closed])

  async function onAssignmentCompletion(id) {
    creationJSON.current = undefined
    const groupSetUrl = `/api/v1/group_categories/${id}?includes[]=unassigned_users_count&includes[]=groups_count`
    const {json} = await apiCall({path: groupSetUrl})
    onDismiss(json)
  }

  function dismissDialog() {
    if (creationJSON.current?.url)
      showFlashSuccess(I18n.t('Group membership assignment will continue in the background'))()
    const result = creationJSON.current
    creationJSON.current = undefined
    onDismiss(result)
  }

  function isInvalidNumber(str) {
    const val = parseInt(str, 10)
    return Number.isNaN(val) || val < 0
  }

  function validateNameSection() {
    if (st.name.trim().length < 1) {
      dispatch({ev: 'error', name: I18n.t('Required')})
      return false
    }
    return true
  }

  function validateStructureSection() {
    let valid = true

    function structureError(str) {
      dispatch({ev: 'error', structure: str})
      valid = false
    }

    if (st.selfSignup) {
      const groupLimitIsInvalid = st.groupLimit.length > 0 && isInvalidNumber(st.groupLimit)
      if (isInvalidNumber(st.createGroupCount)) structureError(I18n.t('Group count is invalid'))
      else if (groupLimitIsInvalid) structureError(I18n.t('Group limit size is invalid'))
      else if (!groupLimitIsInvalid && parseInt(st.groupLimit, 10) < 2)
        structureError(
          I18n.t('If you are going to define a limit group members, it must be greater than 1.')
        )
    } else {
      switch (st.splitGroups) {
        case SPLIT.byGroupCount:
          if (isInvalidNumber(st.createGroupCount)) structureError(I18n.t('Group count is invalid'))
          if (
            st.bySection &&
            studentSectionCount &&
            studentSectionCount > parseInt(st.createGroupCount, 10)
          )
            structureError(
              I18n.t('Must be at least one group per section; there are %{count} sections', {
                count: studentSectionCount,
              })
            )
          break
        case SPLIT.byMemberCount:
          if (isInvalidNumber(st.createGroupMemberCount))
            structureError(I18n.t('Group membership count is invalid'))
          break
      }
    }
    return valid
  }

  function isInputValid() {
    const nameSectionValid = validateNameSection()
    const structureSectionValid = validateStructureSection()
    return nameSectionValid && structureSectionValid
  }

  async function handleSubmit() {
    if (!isInputValid()) {
      const div = topElement.current?.parentElement
      if (div) div.scrollTop = 0
      return
    }

    let step = I18n.t('creating the Group Set')

    try {
      const body = buildPayload()
      const contextStem = context === 'course' ? 'courses' : 'accounts'
      const path = `/api/v1/${contextStem}/${contextId}/group_categories`
      dispatch({ev: 'api-change', to: 'submitting'})
      const {json} = await apiCall({path, body, method: 'POST'})
      showFlashSuccess(I18n.t('Group Set was successfully created'))()
      if (body.assign_async) {
        step = I18n.t('assigning members to the new groups')
        const assignPath = `/api/v1/group_categories/${json.id}/assign_unassigned_members`
        const assignBody = {group_by_section: body.group_by_section}
        const {json: assignJson} = await apiCall({
          path: assignPath,
          body: assignBody,
          method: 'POST',
        })
        if (ASYNC_ACTIVE_STATES.includes(assignJson.workflow_state)) {
          creationJSON.current = assignJson
          dispatch({ev: 'api-change', to: 'assigning'})
          return
        }
      }
      dispatch({ev: 'api-change', to: 'inactive'})
      onDismiss(json)
    } catch (e) {
      showFlashError(
        I18n.t('An error occurred while %{performingSomeTask}: %{errorMessage}', {
          performingSomeTask: step,
          errorMessage: e.message,
        })
      )()
      dispatch({ev: 'api-change', to: 'inactive'})
      onDismiss(null)
    }
  }

  const renderDialogBody = () => (
    <GroupContext.Provider value={stateToContext(st)}>
      <GroupSetName
        errormsg={st.errors.name}
        onChange={newName => dispatch({ev: 'name-change', to: newName})}
        elementRef={el => {
          topElement.current = el
        }}
      />
      {allowSelfSignup && (
        <>
          <Divider />
          <SelfSignup onChange={to => dispatch({ev: 'selfsignup-change', to})} />
          <Divider />
          <GroupStructure
            errormsg={st.errors.structure}
            onChange={to => dispatch({ev: 'structure-change', to})}
          />
          <Divider />
          <Leadership onChange={to => dispatch({ev: 'leadership-change', to})} />
        </>
      )}
    </GroupContext.Provider>
  )

  return (
    <Modal
      label={modalLabel()}
      open={!closed}
      onDismiss={dismissDialog}
      data-testid="modal-create-groupset"
    >
      <Modal.Header>
        <CloseButton
          data-testid="group-set-close"
          placement="end"
          offset="medium"
          onClick={dismissDialog}
          screenReaderLabel={I18n.t('Cancel')}
        />
        <Heading>{modalLabel()}</Heading>
      </Modal.Header>
      <Modal.Body id="foobar">
        {isApiAssigning ? (
          <AssignmentProgress
            url={creationJSON.current.url}
            apiCall={apiCall}
            onCompletion={onAssignmentCompletion}
          />
        ) : (
          renderDialogBody()
        )}
      </Modal.Body>
      <Modal.Footer>
        {isApiActive && <Spinner size="x-small" renderTitle={I18n.t('Saving')} />}
        <Button
          margin="none x-small"
          onClick={dismissDialog}
          interaction={isApiActive ? 'disabled' : 'enabled'}
        >
          {I18n.t('Cancel')}
        </Button>
        <Button
          data-testid="group-set-save"
          color="primary"
          margin="none x-small"
          interaction={areErrors || isApiActive ? 'disabled' : 'enabled'}
          onClick={handleSubmit}
        >
          {I18n.t('Save')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

// TODO: I think allowSelfSignup and context are both conveying the same information...
// check this and remove the redundant prop if true
CreateOrEditSetModal.propTypes = {
  closed: bool,
  onDismiss: func,
  studentSectionCount: number,
  context: string,
  contextId: string,
  allowSelfSignup: bool.isRequired,
  mockApi: func,
}

CreateOrEditSetModal.defaultProps = {
  closed: false,
  onDismiss: Function.prototype,
}

// Brings up the create groupset modal and returns a Promise that resolves when it is dismissed.
// The resolution value is either null if the dialog was dismissed without action or if an error
// occurred, or contains the object returned by the create API call. For testing and Storybook
// purposes, it's also possible to pass in a function which will stand in for doFetchApi to mock
// the API call process. Note that it must return a Promise that resolves to the same data
// structure that doFetchApi returns.
export function renderCreateDialog(div, mockApi) {
  return new Promise(resolve => {
    function onDismiss(result) {
      ReactDOM.render(
        <CreateOrEditSetModal
          allowSelfSignup={ENV.allow_self_signup}
          mockApi={mockApi}
          closed={true}
        />,
        div
      )
      resolve(result)
    }
    const context = ENV.context_asset_string.split('_')
    ReactDOM.render(
      <CreateOrEditSetModal
        studentSectionCount={ENV.student_section_count}
        context={context[0]}
        contextId={context[1]}
        allowSelfSignup={ENV.allow_self_signup}
        onDismiss={onDismiss}
        mockApi={mockApi}
      />,
      div
    )
  })
}
