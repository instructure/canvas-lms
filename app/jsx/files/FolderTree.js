import React from 'react'
import FolderTree from 'compiled/react_files/components/FolderTree'

  FolderTree.render =  function () {
    return (
      <div
        className='ef-folder-list'
        ref='FolderTreeHolder'
      >
      </div>
    );
  };

export default React.createClass(FolderTree)
