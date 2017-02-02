import axios from 'axios'
import I18n from 'i18n!assignment_index_menu'
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
