define [
  'jquery'
  'react'
  'react-router'
  'compiled/react/shared/utils/withReactElement'
  '../modules/customPropTypes'
], ($, React, ReactRouter, withReactElement, customPropTypes) ->

  Link = React.createFactory ReactRouter.Link

  BreadcrumbCollapsedContainer = React.createClass
    displayName: 'BreadcrumbCollapsedContainer'


    propTypes:
      foldersToContain: React.PropTypes.arrayOf(customPropTypes.folder).isRequired

    getInitialState: ->
      open: false

    open: ->
      clearTimeout @timeout
      @setState open: true

    close: ->
      @timeout = setTimeout =>
        @setState open: false
      , 100

    render: withReactElement ->
      li {
          href: '#'
          onMouseEnter: @open
          onMouseLeave: @close
          onFocus: @open
          onBlur: @close
          style: {position: 'relative'}
      },
        a href: '#',
          '…',
        div className: "popover bottom ef-breadcrumb-popover #{'open' if @state.open}",
          div({className: 'arrow'}),
          div className: 'popover-content',
            ul {},
              @props.foldersToContain.map (folder) =>
                li {},
                  Link {
                    to: (if folder.urlPath() then 'folder' else 'rootFolder')
                    params: {splat: folder.urlPath()}
                    activeClassName: 'active'
                    className: 'ellipsis'
                  },
                    i({className: 'ef-big-icon icon-folder'}),
                    span {}, folder.get('name')
