define [
  'react'
  'react-router'
  'compiled/react/shared/utils/withReactDOM'
], (React, Router, withReactDOM) ->

  Toolbar = React.createClass

    onSubmit: (event) ->
      event.preventDefault()
      query = {search_term: @refs.searchTerm.getDOMNode().value}
      Router.transitionTo 'search', @props.params, query

    render: withReactDOM ->
      header className:'ef-header',
        form onSubmit: @onSubmit, className:'ef-search-container',
          i className:'icon-search',
          input type:'search', ref:'searchTerm', defaultValue: @props.query.search_term #, onKeyUp: @onKeyUp
        div className:'ef-main-buttons',
          button className:'btn',
            i className:'icon-plus'
            'Folder'
          button className:'btn btn-primary',
            i className:'icon-plus'
            'Files'
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
