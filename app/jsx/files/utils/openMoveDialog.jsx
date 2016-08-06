define([
  'underscore',
  'react',
  'react-dom',
  'jsx/files/MoveDialog',
  'compiled/react_files/modules/filesEnv',
  'jquery'
], function (_, React, ReactDOM, MoveDialog, filesEnv, $) {

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

  return openMoveDialog;

});
