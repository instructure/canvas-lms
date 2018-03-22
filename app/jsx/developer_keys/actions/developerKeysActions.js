/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import I18n from 'i18n!react_developer_keys'
import $ from 'jquery'
import axios from 'axios'
import parseLinkHeader from '../../shared/parseLinkHeader'

const actions = {}

actions.LIST_DEVELOPER_KEYS_START = 'LIST_DEVELOPER_KEYS_START';
actions.listDeveloperKeysStart = (payload) => ({ type: actions.LIST_DEVELOPER_KEYS_START, payload });

actions.LIST_DEVELOPER_KEYS_SUCCESSFUL = 'LIST_DEVELOPER_KEYS_SUCCESSFUL';
actions.listDeveloperKeysSuccessful = (payload) => ({ type: actions.LIST_DEVELOPER_KEYS_SUCCESSFUL, payload});

actions.LIST_DEVELOPER_KEYS_FAILED = 'LIST_DEVELOPER_KEYS_FAILED';
actions.listDeveloperKeysFailed = (error) => ({ type: actions.LIST_DEVELOPER_KEYS_FAILED, error: true, payload: error });

actions.LIST_DEVELOPER_KEYS_REPLACE = 'LIST_DEVELOPER_KEYS_REPLACE';
actions.listDeveloperKeysReplace = (payload) => ({ type: actions.LIST_DEVELOPER_KEYS_REPLACE, payload});

actions.LIST_DEVELOPER_KEYS_DELETE = 'LIST_DEVELOPER_KEYS_DELETE';
actions.listDeveloperKeysDelete = (payload) => ({ type: actions.LIST_DEVELOPER_KEYS_DELETE, payload});

actions.LIST_DEVELOPER_KEYS_PREPEND = 'LIST_DEVELOPER_KEYS_PREPEND';
actions.listDeveloperKeysPrepend = (payload) => ({ type: actions.LIST_DEVELOPER_KEYS_PREPEND, payload});

actions.DEACTIVATE_DEVELOPER_KEY_START = 'DEACTIVATE_DEVELOPER_KEY_START';
actions.deactivateDeveloperKeyStart = (payload) => ({ type: actions.DEACTIVATE_DEVELOPER_KEY_START, payload });

actions.DEACTIVATE_DEVELOPER_KEY_SUCCESSFUL = 'DEACTIVATE_DEVELOPER_KEY_SUCCESSFUL';
actions.deactivateDeveloperKeySuccessful = (payload) => ({ type: actions.DEACTIVATE_DEVELOPER_KEY_SUCCESSFUL, payload});

actions.DEACTIVATE_DEVELOPER_KEY_FAILED = 'DEACTIVATE_DEVELOPER_KEY_FAILED';
actions.deactivateDeveloperKeyFailed = (error) => ({ type: actions.DEACTIVATE_DEVELOPER_KEY_FAILED, error: true, payload: error });

actions.MAKE_VISIBLE_DEVELOPER_KEY_START = 'MAKE_VISIBLE_DEVELOPER_KEY_START';
actions.makeVisibleDeveloperKeyStart = () => ({ type: actions.MAKE_VISIBLE_DEVELOPER_KEY_START });

actions.MAKE_VISIBLE_DEVELOPER_KEY_SUCCESSFUL = 'MAKE_VISIBLE_DEVELOPER_KEY_SUCCESSFUL';
actions.makeVisibleDeveloperKeySuccessful = () => ({ type: actions.MAKE_VISIBLE_DEVELOPER_KEY_SUCCESSFUL });

actions.MAKE_VISIBLE_DEVELOPER_KEY_FAILED = 'MAKE_VISIBLE_DEVELOPER_KEY_FAILED';
actions.makeVisibleDeveloperKeyFailed = (error) => ({ type: actions.MAKE_VISIBLE_DEVELOPER_KEY_FAILED, error: true, payload: error });

actions.MAKE_INVISIBLE_DEVELOPER_KEY_START = 'MAKE_INVISIBLE_DEVELOPER_KEY_START';
actions.makeInvisibleDeveloperKeyStart = () => ({ type: actions.MAKE_INVISIBLE_DEVELOPER_KEY_START });

actions.MAKE_INVISIBLE_DEVELOPER_KEY_SUCCESSFUL = 'MAKE_INVISIBLE_DEVELOPER_KEY_SUCCESSFUL';
actions.makeInvisibleDeveloperKeySuccessful = () => ({ type: actions.MAKE_INVISIBLE_DEVELOPER_KEY_SUCCESSFUL });

actions.MAKE_INVISIBLE_DEVELOPER_KEY_FAILED = 'MAKE_INVISIBLE_DEVELOPER_KEY_FAILED';
actions.makeInvisibleDeveloperKeyFailed = (error) => ({ type: actions.MAKE_INVISIBLE_DEVELOPER_KEY_FAILED, error: true, payload: error });

actions.DELETE_DEVELOPER_KEY_START = 'DELETE_DEVELOPER_KEY_START';
actions.deleteDeveloperKeyStart = (payload) => ({ type: actions.DELETE_DEVELOPER_KEY_START, payload });

actions.DELETE_DEVELOPER_KEY_SUCCESSFUL = 'DELETE_DEVELOPER_KEY_SUCCESSFUL';
actions.deleteDeveloperKeySuccessful = (payload) => ({ type: actions.DELETE_DEVELOPER_KEY_SUCCESSFUL, payload});

actions.DELETE_DEVELOPER_KEY_FAILED = 'DELETE_DEVELOPER_KEY_FAILED';
actions.deleteDeveloperKeyFailed = (error) => ({ type: actions.DELETE_DEVELOPER_KEY_FAILED, error: true, payload: error });

actions.ACTIVATE_DEVELOPER_KEY_START = 'ACTIVATE_DEVELOPER_KEY_START';
actions.activateDeveloperKeyStart = (payload) => ({ type: actions.ACTIVATE_DEVELOPER_KEY_START, payload });

actions.ACTIVATE_DEVELOPER_KEY_SUCCESSFUL = 'ACTIVATE_DEVELOPER_KEY_SUCCESSFUL';
actions.activateDeveloperKeySuccessful = (payload) => ({ type: actions.ACTIVATE_DEVELOPER_KEY_SUCCESSFUL, payload});

actions.ACTIVATE_DEVELOPER_KEY_FAILED = 'ACTIVATE_DEVELOPER_KEY_FAILED';
actions.activateDeveloperKeyFailed = (error) => ({ type: actions.ACTIVATE_DEVELOPER_KEY_FAILED, error: true, payload: error });

actions.CREATE_OR_EDIT_DEVELOPER_KEY_START = 'CREATE_OR_EDIT_DEVELOPER_KEY_START';
actions.createOrEditDeveloperKeyStart = () => ({ type: actions.CREATE_OR_EDIT_DEVELOPER_KEY_START })

actions.CREATE_OR_EDIT_DEVELOPER_KEY_SUCCESSFUL = 'CREATE_OR_EDIT_DEVELOPER_KEY_SUCCESSFUL';
actions.createOrEditDeveloperKeySuccessful = () => ({ type: actions.CREATE_OR_EDIT_DEVELOPER_KEY_SUCCESSFUL })

actions.CREATE_OR_EDIT_DEVELOPER_KEY_FAILED = 'CREATE_OR_EDIT_DEVELOPER_KEY_FAILED';
actions.createOrEditDeveloperKeyFailed = () => ({ type: actions.CREATE_OR_EDIT_DEVELOPER_KEY_FAILED })

actions.SET_EDITING_DEVELOPER_KEY = 'SET_EDITING_DEVELOPER_KEY';
actions.setEditingDeveloperKey = (payload) => ({type: actions.SET_EDITING_DEVELOPER_KEY, payload})

actions.DEVELOPER_KEYS_MODAL_OPEN = 'DEVELOPER_KEYS_MODAL_OPEN';
actions.developerKeysModalOpen = () => ({type: actions.DEVELOPER_KEYS_MODAL_OPEN})

actions.DEVELOPER_KEYS_MODAL_CLOSE = 'DEVELOPER_KEYS_MODAL_CLOSE';
actions.developerKeysModalClose = () => ({type: actions.DEVELOPER_KEYS_MODAL_CLOSE})

actions.createOrEditDeveloperKey = (formData, url, method) => (dispatch) => {
  dispatch(actions.createOrEditDeveloperKeyStart())

  axios({
    method,
    url,
    data: formData,
    config: { headers: {'Content-Type': 'multipart/form-data' }}
  }).then((response) => {
    if (method === 'post') {
      dispatch(actions.listDeveloperKeysPrepend(response.data))
    } else {
      dispatch(actions.listDeveloperKeysReplace(response.data))
    }
    dispatch(actions.createOrEditDeveloperKeySuccessful())
    dispatch(actions.developerKeysModalClose())
  }).catch(error => {
    $.flashError(error.message)
    dispatch(actions.createOrEditDeveloperKeyFailed())
  }).finally(() => {
    dispatch(actions.setEditingDeveloperKey())
  })
}

actions.getDeveloperKeys = (url, newSearch) => (dispatch, _getState) => {
  dispatch(actions.listDeveloperKeysStart(newSearch));

  axios.get(url)
    .then((response) => {
      const {next} = parseLinkHeader(response.headers.link)
      const payload = {next, developerKeys: response.data}
      dispatch(actions.listDeveloperKeysSuccessful(payload))
    })
    .catch((err) => dispatch(actions.listDeveloperKeysFailed(err)));
};

actions.getRemainingDeveloperKeys = (url, developerKeysPassedIn) => (dispatch, getState) => {
  dispatch(actions.listDeveloperKeysStart());

  axios.get(url)
    .then((response) => {
      const {next} = parseLinkHeader(response.headers.link)
      const developerKeys = developerKeysPassedIn.concat(response.data)
      if (next) {
        dispatch(actions.getRemainingDeveloperKeys(next, developerKeys))
      } else {
        const payload = {next, developerKeys}
        if (getState().listDeveloperKeys.list.length !== 0) {
          $.screenReaderFlashMessageExclusive(I18n.t("Loaded More Developer Keys."));
        }
        dispatch(actions.listDeveloperKeysSuccessful(payload))
      }
    })
    .catch((err) => dispatch(actions.listDeveloperKeysFailed(err)));
};

actions.deactivateDeveloperKey = (developerKey) => (dispatch, _getState) => {
  dispatch(actions.deactivateDeveloperKeyStart());

  const url = `/api/v1/developer_keys/${developerKey.id}`
  axios.put(url,
      {
        developer_key: {event: "deactivate"}
      }
    )
    .then((response) => {
      dispatch(actions.listDeveloperKeysReplace(response.data))
      dispatch(actions.deactivateDeveloperKeySuccessful())
    })
    .catch((err) => dispatch(actions.deactivateDeveloperKeyFailed(err)));
};

actions.activateDeveloperKey = (developerKey) => (dispatch, _getState) => {
  dispatch(actions.activateDeveloperKeyStart());

  const url = `/api/v1/developer_keys/${developerKey.id}`
  axios.put(url,
      {
        developer_key: {event: "activate"}
      }
    )
    .then((response) => {
      dispatch(actions.listDeveloperKeysReplace(response.data))
      dispatch(actions.activateDeveloperKeySuccessful())
    })
    .catch((err) => dispatch(actions.activateDeveloperKeyFailed(err)));
};

actions.makeInvisibleDeveloperKey = (developerKey) => (dispatch, _getState) => {
  dispatch(actions.makeInvisibleDeveloperKeyStart());

  const url = `/api/v1/developer_keys/${developerKey.id}`
  axios.put(url,
      {
        developer_key: {visible: false}
      }
    )
    .then((response) => {
      dispatch(actions.listDeveloperKeysReplace(response.data))
      dispatch(actions.makeInvisibleDeveloperKeySuccessful())
    })
    .catch((err) => dispatch(actions.makeInvisibleDeveloperKeyFailed(err)));
};

actions.makeVisibleDeveloperKey = (developerKey) => (dispatch, _getState) => {
  dispatch(actions.makeVisibleDeveloperKeyStart());

  const url = `/api/v1/developer_keys/${developerKey.id}`
  axios.put(url,
      {
        developer_key: {visible: true}
      }
    )
    .then((response) => {
      dispatch(actions.listDeveloperKeysReplace(response.data))
      dispatch(actions.makeVisibleDeveloperKeySuccessful())
    })
    .catch((err) => dispatch(actions.makeVisibleDeveloperKeyFailed(err)));
};

actions.deleteDeveloperKey = (developerKey) => (dispatch, _getState) => {
  dispatch(actions.deleteDeveloperKeyStart());

  const url = `/api/v1/developer_keys/${developerKey.id}`
  axios.delete(url)
    .then((response) => {
      dispatch(actions.listDeveloperKeysDelete(response.data))
      dispatch(actions.deleteDeveloperKeySuccessful())
    })
    .catch((err) => dispatch(actions.deleteDeveloperKeyFailed(err)));
};

export default actions
