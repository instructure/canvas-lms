/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import I18n from 'i18n!course_wizard'
import axios from '@canvas/axios'
import splitAssetString from '@canvas/util/splitAssetString'
import parseLinkHeader from 'link-header-parsing/parseLinkHeader'
import page from 'page'

const actions = {}

actions.LIST_COLLABORATIONS_START = 'LIST_COLLABORATIONS_START'
actions.listCollaborationsStart = payload => ({type: actions.LIST_COLLABORATIONS_START, payload})

actions.LIST_COLLABORATIONS_SUCCESSFUL = 'LIST_COLLABORATIONS_SUCCESSFUL'
actions.listCollaborationsSuccessful = payload => ({
  type: actions.LIST_COLLABORATIONS_SUCCESSFUL,
  payload
})

actions.LIST_COLLABORATIONS_FAILED = 'LIST_COLLABORATIONS_FAILED'
actions.listCollaborationsFailed = error => ({
  type: actions.LIST_COLLABORATIONS_FAILED,
  error: true,
  payload: error
})

actions.LIST_LTI_COLLABORATIONS_START = 'LIST_LTI_COLLABORATIONS_START'
actions.listLTICollaborationsStart = () => ({type: actions.LIST_LTI_COLLABORATIONS_START})

actions.LIST_LTI_COLLABORATIONS_SUCCESSFUL = 'LIST_LTI_COLLABORATIONS_SUCCESSFUL'
actions.listLTICollaborationsSuccessful = tools => ({
  type: actions.LIST_LTI_COLLABORATIONS_SUCCESSFUL,
  payload: tools
})

actions.LIST_LTI_COLLABORATIONS_FAILED = 'LIST_LTI_COLLABORATIONS_FAILED'
actions.listLTICollaborationsFailed = error => ({
  type: actions.LIST_LTI_COLLABORATIONS_FAILED,
  payload: error,
  error: true
})

actions.DELETE_COLLABORATION_START = 'DELETE_COLLABORATION_START'
actions.deleteCollaborationStart = () => ({type: actions.DELETE_COLLABORATION_START})

actions.DELETE_COLLABORATION_SUCCESSFUL = 'DELETE_COLLABORATION_SUCCESSFUL'
actions.deleteCollaborationSuccessful = deletedCollaborationId => ({
  type: actions.DELETE_COLLABORATION_SUCCESSFUL,
  payload: deletedCollaborationId
})

actions.DELETE_COLLABORATION_FAILED = 'DELETE_COLLABORATION_FAILED'
actions.deleteCollaborationFailed = error => ({
  type: actions.DELETE_COLLABORATION_FAILED,
  payload: error,
  error: true
})

actions.CREATE_COLLABORATION_START = 'CREATE_COLLABORATION_START'
actions.createCollaborationStart = () => ({type: actions.CREATE_COLLABORATION_START})

actions.CREATE_COLLABORATION_SUCCESSFUL = 'CREATE_COLLABORATION_SUCCESSFUL'
actions.createCollaborationSuccessful = collaboration => ({
  type: actions.CREATE_COLLABORATION_SUCCESSFUL,
  payload: collaboration
})

actions.CREATE_COLLABORATION_FAILED = 'CREATE_COLLABORATION_FAILED'
actions.createCollaborationFailed = error => ({
  type: actions.CREATE_COLLABORATION_FAILED,
  payload: error,
  error: true
})

actions.UPDATE_COLLABORATION_START = 'UPDATE_COLLABORATION_START'
actions.updateCollaborationStart = () => ({type: actions.UPDATE_COLLABORATION_START})

actions.UPDATE_COLLABORATION_SUCCESSFUL = 'UPDATE_COLLABORATION_SUCCESSFUL'
actions.updateCollaborationSuccessful = collaboration => ({
  type: actions.UPDATE_COLLABORATION_SUCCESSFUL,
  payload: collaboration
})

actions.UPDATE_COLLABORATION_FAILED = 'UPDATE_COLLABORATION_FAILED'
actions.updateCollaborationFailed = error => ({
  type: actions.UPDATE_COLLABORATION_FAILED,
  payload: error,
  error: true
})

actions.getCollaborations = (url, newSearch) => {
  return (dispatch, getState) => {
    dispatch(actions.listCollaborationsStart(newSearch))

    axios
      .get(url)
      .then(response => {
        const {next} = parseLinkHeader(response.headers.link)
        const payload = {next, collaborations: response.data}
        if (getState().listCollaborations.list.length !== 0) {
          $.screenReaderFlashMessageExclusive(I18n.t('Loaded More Collaborations.'))
        }
        dispatch(actions.listCollaborationsSuccessful(payload))
      })
      .catch(err => dispatch(actions.listCollaborationsFailed(err)))
  }
}

actions.getLTICollaborators = (context, contextId) => {
  return dispatch => {
    dispatch(actions.listLTICollaborationsStart())
    $.getJSON(
      `/api/v1/${context}/${contextId}/external_tools?placement=collaboration&include_parents=true`
    )
      .success(tools => {
        dispatch(actions.listLTICollaborationsSuccessful(tools))
      })
      .fail(error => {
        dispatch(actions.listLTICollaborationsFailed(error))
      })
  }
}

actions.deleteCollaboration = (context, contextId, collaborationId) => {
  return dispatch => {
    dispatch(actions.deleteCollaborationStart())

    const url = `/api/v1/${context}/${contextId}/collaborations/${collaborationId}`
    axios
      .delete(url)
      .then(response => {
        dispatch(actions.deleteCollaborationSuccessful(collaborationId))
        dispatch(actions.getCollaborations(`/api/v1/${context}/${contextId}/collaborations`))
      })
      .catch(err => dispatch(actions.deleteCollaborationFailed(err)))
  }
}

actions.createCollaboration = (context, contextId, contentItems) => {
  return dispatch => {
    dispatch(actions.createCollaborationStart())
    const url = `/${context}/${contextId}/collaborations`
    axios
      .post(
        url,
        {contentItems: JSON.stringify(contentItems)},
        {
          headers: {
            Accept: 'application/json'
          }
        }
      )
      .then(({data}) => {
        dispatch(actions.createCollaborationSuccessful(data))
        page(`/${context}/${contextId}/lti_collaborations`)
      })
      .catch(error => {
        dispatch(actions.createCollaborationFailed(error))
      })
  }
}

actions.updateCollaboration = (context, contextId, contentItems, collaborationId) => {
  return dispatch => {
    dispatch(actions.updateCollaborationStart())
    const url = `/${context}/${contextId}/collaborations/${collaborationId}`
    axios
      .put(
        url,
        {contentItems: JSON.stringify(contentItems)},
        {
          headers: {
            Accept: 'application/json'
          }
        }
      )
      .then(({collaboration}) => {
        page(`/${context}/${contextId}/lti_collaborations`)
        dispatch(actions.updateCollaborationSuccessful(collaboration))
      })
      .catch(error => {
        dispatch(actions.updateCollaborationFailed(error))
      })
  }
}

actions.externalContentReady = ({contentItems, service_id}) => {
  return dispatch => {
    const [context, contextId] = splitAssetString(ENV.context_asset_string)
    if (service_id) {
      dispatch(actions.updateCollaboration(context, contextId, contentItems, service_id))
    } else {
      dispatch(actions.createCollaboration(context, contextId, contentItems))
    }
  }
}

actions.externalContentRetrievalFailed = () => {
  $.flashError(I18n.t('Error retrieving content from tool'))
  const [context, contextId] = splitAssetString(ENV.context_asset_string)
  page(`/${context}/${contextId}/lti_collaborations`)
}

export default actions
