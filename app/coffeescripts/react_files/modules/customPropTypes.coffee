define [
  'react'
  'compiled/models/Folder'
  'compiled/models/FilesystemObject'
], (React, Folder, FilesystemObject) ->

  customPropTypes =
    contextType: React.PropTypes.oneOf(['users', 'groups', 'accounts', 'courses'])
    contextId: React.PropTypes.oneOfType([React.PropTypes.string, React.PropTypes.number])
    folder: React.PropTypes.instanceOf(Folder)
    filesystemObject: React.PropTypes.instanceOf(FilesystemObject)

