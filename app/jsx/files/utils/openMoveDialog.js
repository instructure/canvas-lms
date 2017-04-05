import _ from 'underscore'
import React from 'react'
import ReactDOM from 'react-dom'
import MoveDialog from 'jsx/files/MoveDialog'
import filesEnv from 'compiled/react_files/modules/filesEnv'
import $ from 'jquery'

  function openMoveDialog (thingsToMove, {contextType, contextId, returnFocusTo, clearSelectedItems, onMove}) {

    const rootFolderToShow = _.find(filesEnv.rootFolders, (folder) => {
      return (`${folder.get('context_type').toLowerCase()}s` === contextType) && (String(folder.get('context_id')) === String(contextId));
    });

    const $moveDialog = $('<div>').appendTo(document.body);

    const handleClose = () => {
      ReactDOM.unmountComponentAtNode($moveDialog[0]);
      $moveDialog.remove();
      $(returnFocusTo).focus();
    };

    const handleMove = (models) => {
      onMove(models) && clearSelectedItems();
    };

    ReactDOM.render(
      <MoveDialog
        thingsToMove={thingsToMove}
        rootFoldersToShow={(filesEnv.showingAllContexts) ? filesEnv.rootFolders : [rootFolderToShow] }
        onClose={handleClose}
        onMove={handleMove}
      />
    , $moveDialog[0]
    );
  }

export default openMoveDialog
