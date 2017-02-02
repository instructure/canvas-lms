import React from 'react'
import ReactDOM from 'react-dom'
import customPropTypes from 'compiled/react_files/modules/customPropTypes'
import I18n from 'i18n!react_files'
import BBTreeBrowserView from 'compiled/react_files/modules/BBTreeBrowserView'
import RootFoldersFinder from 'compiled/views/RootFoldersFinder'
  var BBTreeBrowser = React.createClass({
    displayName: "BBTreeBrowser",
    propTypes: {
      rootFoldersToShow: React.PropTypes.arrayOf(customPropTypes.folder).isRequired,
      onSelectFolder: React.PropTypes.func.isRequired
    },
    componentDidMount(){
      var rootFoldersFinder = new RootFoldersFinder({
        rootFoldersToShow: this.props.rootFoldersToShow
      })

      this.treeBrowserViewId = BBTreeBrowserView.create({
        onlyShowSubtrees: true,
        rootModelsFinder: rootFoldersFinder,
        rootFoldersToShow: this.props.rootFoldersToShow,
        onClick: this.props.onSelectFolder,
        focusStyleClass: 'MoveDialog__folderItem--focused',
        selectedStyleClass: 'MoveDialog__folderItem--selected'
      },
      {
        element: ReactDOM.findDOMNode(this.refs.FolderTreeHolder)
      }).index

      window.setTimeout(function(){
        BBTreeBrowserView.getView(this.treeBrowserViewId).render().$el.appendTo(ReactDOM.findDOMNode(this.refs.FolderTreeHolder)).find(':tabbable:first').focus()
      }.bind(this), 0);
    },
    componentWillUnmount(){
      BBTreeBrowserView.remove(this.treeBrowserViewId)
    },
    render(){
      return(
        <aside role='region' aria-label={I18n.t('folder_browsing_tree', 'Folder Browsing Tree')}>
          <div ref="FolderTreeHolder"></div>
        </aside>
      );
    }
  });
export default BBTreeBrowser
