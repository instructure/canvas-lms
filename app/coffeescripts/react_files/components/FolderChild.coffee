define [
  'react'
  'react-router'
  '../mixins/BackboneMixin'
  'compiled/react/shared/utils/withReactDOM'
  './FriendlyDatetime'
  './ItemCog'
  'compiled/util/friendlyBytes'
], (React, {Link}, BackboneMixin, withReactDOM, FriendlyDatetime, ItemCog, friendlyBytes) ->


  FolderChild = React.createClass

    mixins: [BackboneMixin('model')],

    render: withReactDOM ->
      div className:'ef-item-row',
        div className:'ef-name-col',
          if @props.model.get('display_name')
            a href: @props.model.get('url'),
              if @props.model.get('thumbnail_url')
                img src: @props.model.get('thumbnail_url'), className:'ef-thumbnail', alt:''
              else
                i className:'icon-document'
              @props.model.get('display_name')
          else
            Link to: 'folder', contextType: @props.params.contextType, contextId: @props.params.contextId, splat: @props.model.urlPath(),
              i className:'icon-folder',
              @props.model.get('name')
        div className:'ef-date-modified-col',
          FriendlyDatetime datetime: @props.model.get('updated_at'),
        div className:'ef-modified-by-col',
          a href: @props.model.get('user')?.html_url,
            @props.model.get('user')?.display_name,
        div className:'ef-size-col',
          friendlyBytes(@props.model.get('size')),
        div( {className:'ef-links-col'},
          span( {'data-module-type':'assignment', 'data-content-id':'6', 'data-id':'6', 'data-course-id':'4', 'data-module-id':'3', 'data-module-item-id':'3', 'data-published':'true', 'data-publishable':'true', 'data-unpublishable':'true', className:'publish-icon published publish-icon-published', role:'button', tabIndex:'0', 'aria-pressed':'true', title:'Published', 'aria-describedby':'ui-tooltip-1', 'aria-label':'Published. Click to unpublish.'}, i( {className:'icon-publish'}),
            span( {className:'publish-text', tabIndex:'-1'}, ' Published'),
            span( {className:'screenreader-only accessible_label'}, 'Published. Click to unpublish.'),
            span( {className:'screenreader-only accessible_label'}, 'Published. Click to unpublish.'),
            span( {className:'screenreader-only accessible_label'}, 'Published. Click to unpublish.')
          ),

          ItemCog(model: @props.model)
        )
