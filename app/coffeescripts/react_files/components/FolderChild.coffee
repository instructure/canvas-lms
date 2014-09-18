define [
  'i18n!react_files'
  'react'
  'react-router'
  '../mixins/BackboneMixin'
  'compiled/react/shared/utils/withReactDOM'
  './FriendlyDatetime'
  './ItemCog'
  'compiled/util/friendlyBytes'
  'compiled/models/Folder'
  'compiled/fn/preventDefault'
  './PublishCloud'
], (I18n, React, {Link}, BackboneMixin, withReactDOM, FriendlyDatetime, ItemCog, friendlyBytes, Folder, preventDefault, PublishCloud) ->


  FolderChild = React.createClass
    displayName: 'FolderChild'

    mixins: [BackboneMixin('model')],

    getInitialState: ->
      editing: @props.model.isNew()

    componentDidMount: ->
      @focusNameInput() if @state.editing

    startEditingName: ->
      @setState editing: true, @focusNameInput

    focusNameInput: ->
      @refs.newName.getDOMNode().focus()

    saveNameEdit: ->
      @props.model.save(name: @refs.newName.getDOMNode().value)
      @setState(editing: false)


    cancelEditingName: ->
      @props.model.collection.remove(@props.model) if @props.model.isNew()
      @setState(editing: false)


    render: withReactDOM ->
      div {
        onClick: @props.toggleSelected
        className: "ef-item-row #{'ef-item-selected' if @props.isSelected}"
        role: 'row'
        'aria-selected': @props.isSelected
      },
        label className: 'screenreader-only', role: 'gridcell',
          input {
            type: 'checkbox'
            className: 'multiselectable-toggler'
            checked: @props.isSelected
            onChange: ->
          }
          I18n.t('labels.select', 'Select This Item')

        div className:'ef-name-col ellipsis', role: 'rowheader',
          if @state.editing
            form className: 'ef-edit-name-form', onSubmit: preventDefault(@saveNameEdit),
              input({
                type:'text'
                ref:'newName'
                className: 'input-block-level'
                placeholder: I18n.t('name', 'Name')
                'aria-label': I18n.t('folder_name', 'Folder Name')
                defaultValue: @props.model.displayName()
                onKeyUp: (event) => @cancelEditingName() if event.keyCode is 27
              }),
              button {
                type: 'button'
                className: 'btn btn-link ef-edit-name-cancel'
                'aria-label': I18n.t('cancel', 'Cancel')
                onClick: @cancelEditingName
              },
                i className: 'icon-x'
          else if @props.model instanceof Folder
            Link {
              to: 'folder'
              splat: @props.model.urlPath()
              className: 'media'
            },
              span className: 'pull-left',
                i className: 'icon-folder media-object ef-big-icon'
              span className: 'media-body',
                @props.model.displayName()
          else
            a href: @props.model.get('url'), className: 'media',
              span className: 'pull-left',
                if @props.model.get('thumbnail_url')
                  span
                    className: 'media-object ef-thumbnail'
                    style:
                      backgroundImage: "url('#{ @props.model.get('thumbnail_url') }')"
                else
                  i className:'icon-document media-object ef-big-icon'
              span className: 'media-body',
                @props.model.displayName()

        div className: 'screenreader-only', role: 'gridcell',
          if @props.model instanceof Folder
            I18n.t('folder', 'Folder')
          else
            @props.model.get('content-type')


        div className:'ef-date-created-col', role: 'gridcell',
          FriendlyDatetime datetime: @props.model.get('created_at')

        div className:'ef-date-modified-col', role: 'gridcell',
          FriendlyDatetime datetime: @props.model.get('updated_at')

        div className:'ef-modified-by-col ellipsis', role: 'gridcell',
          a href: @props.model.get('user')?.html_url, className: 'ef-plain-link',
            @props.model.get('user')?.display_name

        div className:'ef-size-col', role: 'gridcell',
          friendlyBytes(@props.model.get('size'))

        div className: 'ef-links-col', role: 'gridcell',
          if @props.userCanManageFilesForContext
            PublishCloud(model: @props.model, ref: 'publishButton')
          ItemCog(model: @props.model, startEditingName: @startEditingName, userCanManageFilesForContext: @props.userCanManageFilesForContext)
