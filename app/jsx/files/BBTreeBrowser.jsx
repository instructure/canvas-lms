/** @jsx React.DOM */

define([
  'react',
  'compiled/react_files/modules/customPropTypes',
  'i18n!react_files',
  'compiled/react_files/modules/BBTreeBrowserView',
  'compiled/views/RootFoldersFinder'
], function (React, customPropTypes, I18n, BBTreeBrowserView, RootFoldersFinder) {
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
        element: this.refs.FolderTreeHolder.getDOMNode()
      }).index

      window.setTimeout(function(){
        BBTreeBrowserView.getView(this.treeBrowserViewId).render().$el.appendTo(this.refs.FolderTreeHolder.getDOMNode()).find(':tabbable:first').focus()
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
  return BBTreeBrowser;
});
