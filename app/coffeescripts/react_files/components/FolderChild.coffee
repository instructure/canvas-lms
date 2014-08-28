define [
  'react'
  '../mixins/BackboneMixin'
  '../utils/withGlobalDom'
  './FriendlyDatetime'
  'compiled/util/friendlyBytes'
], (React, BackboneMixin, withGlobalDom, FriendlyDatetime, friendlyBytes) ->

  EVERYTHING_BEFORE_THE_FIRST_SLASH = /^[^\/]+/


  FolderChild = React.createClass

    mixins: [BackboneMixin('model')],

    folderHref: ->
      @props.baseUrl + 'folder' + @props.model.get('full_name').replace(EVERYTHING_BEFORE_THE_FIRST_SLASH, '')

    render: withGlobalDom ->

      div className:'ef-item-row',
        div className:'ef-name-col',
          (if @props.model.get('display_name')
            a href: @props.model.get('url'),
              (if @props.model.get('thumbnail_url')
                img src: @props.model.get('thumbnail_url'), className:'ef-thumbnail', alt:''
              else
                i className:'icon-document'
              ),
              @props.model.get('display_name')
          else
            a href: @folderHref(),
              i className:'icon-folder'
              @props.model.get('name')
          )
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

          div( {className:'ef-hover-options'},
            a( {herf:'#', style: {'color': 'black', 'margin-right': '10px'}}, i( {className:'icon-download'})),
            div( {className:'ef-admin-gear'},
              div(null,
                a( {className:'al-trigger al-trigger-gray', role:'button', 'aria-haspopup':'true', 'aria-owns':'content-1', 'aria-label':'Settings', href:'#'},
                  i( {className:'icon-settings'}),
                  i( {className:'icon-mini-arrow-down'})
                ),

                ul( {id:'content-1', className:'al-options', role:'menu', tabIndex:'0', 'aria-hidden':'true', 'aria-expanded':'false', 'aria-activedescendant':'content-2'},
                  li( {role:'presentation'},
                  a( {href:'#', className:'icon-edit', id:'content-2', tabIndex:'-1', role:'menuitem', title:'Edit'}, 'Edit')
                  ),
                  li( {role:'presentation'},
                  a( {href:'#', className:'icon-trash', id:'content-3', tabIndex:'-1', role:'menuitem', title:'Delete this module'}, 'Delete')
                  )
                )
              )
            )
          )
        )