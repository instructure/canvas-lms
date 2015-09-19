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
  'jsx/files/DialogPreview'
  'compiled/react/shared/utils/withReactElement'
  'compiled/jquery.rails_flash_notifications'
  'jquery.instructure_forms'
], ($, _, React, I18n, preventDefault, customPropTypes, Folder, UsageRightsSelectBoxComponent, filesEnv, setUsageRights, updateModelsUsageRights, DialogPreview, withReactElement) ->

  UsageRightsSelectBox = React.createFactory UsageRightsSelectBoxComponent

  MAX_THUMBNAILS_TO_SHOW = 5
  MAX_FOLDERS_TO_SHOW = 2

  ManageUsageRightsModal = React.createClass
    displayName: 'ManageUsageRightsModal'

    propTypes:
      closeModal: React.PropTypes.func
      itemsToManage: React.PropTypes.arrayOf(customPropTypes.filesystemObject).isRequired


    componentWillMount: ->
      @copyright = @defaultCopyright()
      @use_justification = @defaultSelectedRight()
      @cc_value = @defaultCCValue()

    apiUrl: "/api/v1/#{filesEnv.contextType}/#{filesEnv.contextId}/usage_rights"

    copyright: null
    use_justification: null

    submit: ->
      values = @refs.usageSelection.getValues()

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
        @props.closeModal()

      setUsageRights(@props.itemsToManage, usageRightValue, afterSet)

    # Determines the default usage right to be selected
    defaultSelectedRight: ->
      useJustification = @props.itemsToManage[0].get('usage_rights')?.use_justification
      if @props.itemsToManage.every((item) -> item.get('usage_rights')?.use_justification is useJustification)
        useJustification
      else
        'choose'

    defaultCopyright: ->
      copyright = @props.itemsToManage[0].get('usage_rights')?.legal_copyright || ''
      if @props.itemsToManage.every((item) -> (item.get('usage_rights')?.legal_copyright == copyright) || (item.get('usage_rights')?.license == copyright))
        copyright
      else
        '' # They have different copyrights

    defaultCCValue: ->
      if (@use_justification == 'creative_commons')
        @props.itemsToManage[0].get('usage_rights')?.license
      else
        null

    renderFileName: ->
      textToShow = if @props.itemsToManage.length > 1
        I18n.t("%{items} items selected", {items: @props.itemsToManage.length})
      else @props.itemsToManage[0]?.displayName()

      span {ref: "fileName" ,className: 'UsageRightsDialog__fileName'},
        textToShow

    renderFolderMessage: ->
      folders = @props.itemsToManage.filter (item) ->
        item instanceof Folder
      foldersToShow = folders.slice(0, MAX_FOLDERS_TO_SHOW)
      toolTipFolders = folders.slice(MAX_FOLDERS_TO_SHOW)
      div {},
        if (folders.length)
          div {},
            span {},
              I18n.t("Usage rights will be set for all of the files contained in:")
            ul {ref: "folderBulletList", className: 'UsageRightsDialog__folderBulletList'},
              foldersToShow.map (item) ->
                li {},
                  item?.displayName()
        if (toolTipFolders.length)
          displayNames = toolTipFolders.map (item) -> item?.displayName()
          # Doing it this way so commas, don't show up when rendering the list out in the tooltip.
          renderedNames = displayNames.join('<br />')
          span {
            className: 'UsageRightsDialog__andMore'
            tabIndex: '0'
            ref: 'folderTooltip'
            title: renderedNames
            'data-tooltip': 'right'
            'data-tooltip-class': 'UsageRightsDialog__tooltip'
          },
            I18n.t("and %{count} more…", {count: toolTipFolders.length})
            span {className: 'screenreader-only'},
              ul {},
                displayNames.map (item) ->
                  li {ref: 'displayNameTooltip-screenreader'},
                    item
        hr {}

    renderDifferentRightsMessage: ->
      span {ref: 'differentRightsMessage', className: 'UsageRightsDialog__differentRightsMessage alert'},
        i {className: 'icon-warning UsageRightsDialog__warning'}
        I18n.t('Items selected have different usage rights.')

    render: withReactElement ->
      div {className: 'ReactModal__Layout'},
        div {className: 'ReactModal__Header'},
          div {className: 'ReactModal__Header-Title'},
            h4 {},
              I18n.t('Manage Usage Rights')
          div {className: 'ReactModal__Header-Actions'},
            button {ref: 'cancelXButton', className: 'Button Button--icon-action', type: 'button', onClick: @props.closeModal},
              i {className: 'icon-x'},
                span {className: 'screenreader-only'},
                  I18n.t('Close')
        div {className: 'ReactModal__Body'},
          div { ref: 'form', className: 'form-dialog'},
            div {},
              div {className: 'UsageRightsDialog__paddingFix grid-row'},
                div {className: 'UsageRightsDialog__previewColumn col-xs-3'},
                  DialogPreview(itemsToShow: @props.itemsToManage)
                div {className: 'UsageRightsDialog__contentColumn off-xs-1 col-xs-8'},
                  @renderDifferentRightsMessage() if ((@copyright == '' || @usageRight == 'choose') && @props.itemsToManage.length > 1 && @copyright != "undefined")
                  @renderFileName()
                  @renderFolderMessage()
                  UsageRightsSelectBox {
                    ref: 'usageSelection'
                    use_justification: @use_justification
                    copyright: @copyright
                    cc_value: @cc_value
                  }
        div {className: 'ReactModal__Footer'},
          div {className: 'ReactModal__Footer-Actions'},
            button {
              ref: 'cancelButton'
              type: 'button'
              className: 'btn'
              onClick: @props.closeModal
            },
              I18n.t('Cancel')
            button {
              ref: "saveButton"
              type: 'button'
              onClick: @submit
              className: 'btn btn-primary'
            },
              I18n.t('Save')
