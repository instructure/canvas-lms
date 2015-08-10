/** @jsx React.DOM */

define([
  'react',
  'compiled/react_files/components/FolderTree'

  ], function(React, FolderTree) {

  FolderTree.render =  function () {
    return (
      <div
        className='ef-folder-list'
        ref='FolderTreeHolder'
      >
      </div>
    );
  };

  return React.createClass(FolderTree);

});