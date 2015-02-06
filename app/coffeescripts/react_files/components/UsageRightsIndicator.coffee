define [
  'i18n!react_files'
  'old_unsupported_dont_use_react'
  '../modules/customPropTypes'
  'compiled/models/Folder'
  '../modules/filesEnv'
  './UsageRightsDialog'
], (I18n, React, customPropTypes, Folder, filesEnv, UsageRightsDialog) ->

  {button, span, i} = React.DOM

  UsageRightsIndicator = React.createClass
    displayName: 'UsageRightsIndicator'

    warningMessage: I18n.t('Before publishing this file, you must specify usage rights.')

    propTypes:
      model: customPropTypes.filesystemObject.isRequired
      userCanManageFilesForContext: React.PropTypes.bool.isRequired
      usageRightsRequiredForContext: React.PropTypes.bool.isRequired
      modalOptions: React.PropTypes.object.isRequired

    handleClick: (event) ->
      event.preventDefault()

      contents = UsageRightsDialog(
        closeModal: @props.modalOptions.closeModal
        itemsToManage: [@props.model]
      )

      @props.modalOptions.openModal(contents, => @getDOMNode().focus())

    render: ->
      if (@props.model instanceof Folder) || (!@props.usageRightsRequiredForContext && !@props.model.get('usage_rights'))
        null
      else if (@props.usageRightsRequiredForContext && !@props.model.get('usage_rights'))
        if @props.userCanManageFilesForContext
          button {
              className: 'UsageRightsIndicator__openModal btn-link'
              onClick: @handleClick
              title: @warningMessage
              'data-tooltip': 'top'
            },
              span {className: 'screenreader-only'},
                @warningMessage
              i {className: 'UsageRightsIndicator__warning icon-warning'}
        else
          null
      else
        useJustification = @props.model.get('usage_rights').use_justification
        iconClass = switch useJustification
          when 'own_copyright' then 'icon-files-copyright'
          when 'public_domain' then 'icon-files-public-domain'
          when 'used_by_permission' then 'icon-files-obtained-permission'
          when 'fair_use' then 'icon-files-fair-use'
          when 'creative_commons' then 'icon-files-creative-commons'
        button {
          className: 'UsageRightsIndicator__openModal btn-link'
          onClick: @handleClick
          disabled: !@props.userCanManageFilesForContext
          title: @props.model.get('usage_rights').license_name
          'data-tooltip': 'top'
          },
            span {className: 'screenreader-only'},
              switch useJustification
                when 'own_copyright' then I18n.t('Own Copyright')
                when 'public_domain' then I18n.t('Public Domain')
                when 'used_by_permission' then I18n.t('Used by Permission')
                when 'fair_use' then I18n.t('Fair Use')
                when 'creative_commons' then I18n.t('Creative Commons')
            span {className: 'screenreader-only'},
              @props.model.get('usage_rights').license_name
            i {className: iconClass}
