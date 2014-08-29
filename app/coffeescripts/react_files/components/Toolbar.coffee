define [
  'i18n!react_files'
  'react'
  'react-router'
  'compiled/react/shared/utils/withReactDOM'
  './UploadButton'
], (I18n, React, Router, withReactDOM, UploadButton) ->

  Toolbar = React.createClass

    propTypes:
      currentFolder: React.PropTypes.object # not required as we don't have it on the first render

    onSubmitSearch: (event) ->
      event.preventDefault()
      query = {search_term: @refs.searchTerm.getDOMNode().value}
      Router.transitionTo 'search', @props.params, query

    addFolder: ->
      @props.currentFolder.folders.add({})

    render: withReactDOM ->
      header className:'ef-header',
        form onSubmit: @onSubmitSearch, className:'ef-search-container',
          i className:'icon-search',
          input placeholder: I18n.t('search', 'Search for files'), type:'search', ref:'searchTerm', defaultValue: @props.query.search_term #, onKeyUp: @onKeyUp
        div className:'ef-main-buttons',
          button onClick: @addFolder, className:'btn',
            i className:'icon-plus'
            'Folder'
          UploadButton currentFolder: this.props.currentFolder
          a className:'ef-admin-cog al-trigger btn', role:'button', 'aria-haspopup':'true', 'aria-owns':'toolbar-1', 'aria-label':'Settings', href:'#',
            i className:'icon-settings'
            i className:'icon-mini-arrow-down'
          ul id:'toolbar-1', className:'al-options', role:'menu', tabIndex:'0', 'aria-hidden':'true', 'aria-expanded':'false', 'aria-activedescendant':'toolbar-2',
            li role:'presentation',
              a href:'#', className:'icon-edit', id:'toolbar-2', tabIndex:'-1', role:'menuitem', 'Edit'
            li role:'presentation',
              a href:'#', className:'icon-trash', id:'toolbar-3', tabIndex:'-1', role:'menuitem', 'Delete'
            li role:'presentation',
              a href:'#', className:'icon-lock', id:'toolbar-4', tabIndex:'-1', role:'menuitem', 'Lock'
