define [
  'react'
  '../utils/withGlobalDom'
], (React, withGlobalDom) ->

  Breadcrumbs = React.createClass

    propTypes:
      folderPath: React.PropTypes.string.isRequired


    getCrumbs: ->
      # TODO: this doesn't update once we know the root folder's name
      for segment, i in (split = @props.folderPath.split('/'))
        if i is 0
          name: @props.currentFolder?.get('full_name') || 'Files'
          url: @props.baseUrl
          key: i
        else
          name: decodeURIComponent(segment)
          url: @props.baseUrl + 'folder' + split[0..i].join('/')
          last: i is split.length - 1
          key: i

    render: withGlobalDom ->
      nav 'aria-label':'breadcrumbs', role:'navigation', className:'ef-breadcrumbs',
        @getCrumbs().map (crumb) ->
          a key: crumb.key, href: crumb.url, className: ('active' if crumb.last),
            span className:'ellipsible', crumb.name



