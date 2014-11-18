define [
  'jquery'
  'underscore'
  'react'
  'i18n!usage_rights_modal'
  'compiled/fn/preventDefault'
  '../modules/customPropTypes'
  'compiled/models/Folder'
  './UsageRightsSelectBox'
  '../modules/filesEnv'
  '../utils/setUsageRights'
  '../utils/updateModelsUsageRights'
  './FilesystemObjectThumbnail'
  './DialogPreview'
  'compiled/jquery.rails_flash_notifications'
  'jquery.instructure_forms'
], ($, _, React, I18n, preventDefault, customPropTypes, Folder, UsageRightsSelectBox, filesEnv, setUsageRights, updateModelsUsageRights, FilesystemObjectThumbnail, DialogPreview) ->

  {div, form, button, span, ul, li, i} = React.DOM

  MAX_THUMBNAILS_TO_SHOW = 5

  ManageUsageRightsModal = React.createClass
    displayName: 'ManageUsageRightsModal'

    propTypes:
      closeDialog: React.PropTypes.func
      setTitle: React.PropTypes.func
      itemsToManage: React.PropTypes.arrayOf(customPropTypes.filesystemObject).isRequired


    componentWillMount: ->
      @copyright = @defaultCopyright()
      @use_justification = @defaultSelectedRight()

    apiUrl: "/api/v1/#{filesEnv.contextType}/#{filesEnv.contextId}/usage_rights"

    copyright: null
    use_justification: null

    submit: ->
      values = @refs.usageSelection.getValue()

      # No copyright specified
      if (!values.copyright)
        $(@refs.usageSelection.refs.copyright.getDOMNode()).errorBox(I18n.t('You must specify the copyright holder.'))
        return false
      # They didn't choose a copyright
      if (values.use_justification == 'choose')
        $(@refs.usageSelection.refs.usageRightSelection.getDOMNode()).errorBox(I18n.t('You must specify a usage right.'))
        return false

      usageRightValue =
        use_justification: values.use_justification
        legal_copyright: values.copyright
        license: values.cc_license

      afterSet = (success, data) =>
        if success
          updateModelsUsageRights(data, @props.itemsToManage)
          $.flashMessage(I18n.t('Usage rights have been set.'))
        else
          $.flashError(I18n.t('There was an error setting usage rights.'))
        @props.closeDialog()

      setUsageRights(@props.itemsToManage, usageRightValue, afterSet)

    # Determines the default usage right to be selected
    defaultSelectedRight: ->
      useJustification = @props.itemsToManage[0].get('usage_rights')?.use_justification
      if @props.itemsToManage.every((item) -> item.get('usage_rights')?.use_justification is useJustification)
        useJustification
      else
        'choose'

    defaultCopyright: ->
      copyright = @props.itemsToManage[0].get('usage_rights')?.legal_copyright || @props.itemsToManage[0].get('usage_rights')?.license
      if @props.itemsToManage.every((item) -> (item.get('usage_rights')?.legal_copyright == copyright) || (item.get('usage_rights')?.license == copyright))
        copyright
      else
        '' # They have different copyrights

    renderFileName: ->
      textToShow = if @props.itemsToManage.length > 1
        I18n.t("%{items} items selected", {items: @props.itemsToManage.length})
      else @props.itemsToManage[0]?.displayName()

      span {className: 'UsageRightsDialog__fileName'},
        textToShow

    renderFolderMessage: ->
      folders = @props.itemsToManage.filter (item) ->
        item instanceof Folder



      div {},
        if (folders.length > 0)
          I18n.t({
            one: "Usage rights will be set for all of the files contained in %{name}",
            other: "Usage rights will be set for all of the files contained in:"
          }, {
            count: folders.length
            name: folders[0]?.displayName()
          })
        if folders.length > 1
          ul {},
            folders.map (item) ->
              li {},
                item?.displayName()

    renderDifferentRightsMessage: ->
      span {className: 'UsageRightsDialog__differentRightsMessage'},
        i {className: 'icon-warning UsageRightsDialog__warning'}
        I18n.t('You have selected multiple items with different licenses, however they will all be set to the one you select now.')

    render: ->
      form { ref: 'form', className: 'form-dialog form-horizontal', onSubmit: preventDefault(@submit)},
        div {className: 'form-dialog-content'},
          div {className: 'UsageRightsDialog__content grid-row'},
            div {className: 'UsageRightsDialog__previewColumn col-xs-3'},
              DialogPreview(itemsToShow: @props.itemsToManage)
            div {className: 'UsageRightsDialog__contentColumn col-xs-9'},
              @renderFileName()
              @renderFolderMessage()
              @renderDifferentRightsMessage() if ((@copyright == '' || @usageRight == 'choose') && @props.itemsToManage.length > 1 && @copyright != "undefined")
              UsageRightsSelectBox(ref: 'usageSelection', use_justification: @use_justification, copyright: @copyright)

        div {className: 'form-controls'},
          button {
            type: 'button'
            className: 'btn'
            onClick: @props.closeDialog
          }, I18n.t('Cancel')
          button {
            type: 'submit'
            className: 'btn btn-primary'
            'data-text-while-loading': I18n.t('saving', 'Saving...')
          }, I18n.t('Save')