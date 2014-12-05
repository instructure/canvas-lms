define [
  'i18n!react_files'
  'react'
  '../modules/customPropTypes'
  'compiled/models/Folder'
  '../modules/filesEnv'
  '../utils/openUsageRightsDialog'
], (I18n, React, customPropTypes, Folder, filesEnv, openUsageRightsDialog) ->

  {button, i} = React.DOM

  UsageRightsIndicator = React.createClass
    displayName: 'UsageRightsIndicator'

    propTypes:
      model: customPropTypes.filesystemObject.isRequired
      userCanManageFilesForContext: React.PropTypes.bool
      usageRightsRequiredForContext: React.PropTypes.bool

    handleClick: (event) ->
      event.preventDefault()

      openUsageRightsDialog([@props.model], {returnFocusTo: @getDOMNode()})


    render: ->
      if (@props.model instanceof Folder) || (!@props.usageRightsRequiredForContext && !@props.model.get('usage_rights'))
        null
      else if (@props.usageRightsRequiredForContext && !@props.model.get('usage_rights'))
        button {
            className: 'UsageRightsIndicator__openModal btn-link'
            onClick: @handleClick
            title: I18n.t('Before publishing this file, you must specify usage rights.')
            'data-tooltip': 'top'
          },
                i {className: 'UsageRightsIndicator__warning icon-warning'}
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
          title: @props.model.get('usage_rights').license_name
          'data-tooltip': 'top'
          },
            i {className: iconClass}
