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

import axios from 'axios'

  const IndexMenuActions = {

    // Define 'constants' for types
    SET_MODAL_OPEN: 'SET_MODAL_OPEN',
    LAUNCH_TOOL: 'LAUNCH_TOOL',
    SET_TOOLS: 'SET_TOOLS',
    SET_WEIGHTED: 'SET_WEIGHTED',

    setModalOpen (value) {
      return {
        type: this.SET_MODAL_OPEN,
        payload: !!value,
      };
    },

    launchTool (tool) {
      return {
        type: this.LAUNCH_TOOL,
        payload: tool,
      };
    },

    apiGetLaunches (ajaxLib, endpoint) {
      return (dispatch) => {
        (ajaxLib || axios).get(endpoint)
          .then((response) => {
            dispatch({
              type: this.SET_TOOLS,
              payload: response.data,
            });
          })
          .catch((response) => {
            throw new Error(response);
          });
      }
    },

    setWeighted (value) {
      return {
        type: this.SET_WEIGHTED,
        payload: value,
      };
    }
  };

export default IndexMenuActions
