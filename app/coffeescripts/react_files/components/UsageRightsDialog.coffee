define [
  'jquery'
  'underscore'
  'react'
  'i18n!usage_rights_modal'
  'compiled/fn/preventDefault'
  '../modules/customPropTypes'
  'compiled/models/Folder'
  'jsx/files/UsageRightsSelectBox'
  '../modules/filesEnv'
  '../utils/setUsageRights'
  '../utils/updateModelsUsageRights'
  'jsx/files/DialogPreview'
  'compiled/react/shared/utils/withReactElement'
  'compiled/jquery.rails_flash_notifications'
  'jquery.instructure_forms'
], ($, _, React, I18n, preventDefault, customPropTypes, Folder, UsageRightsSelectBox, filesEnv, setUsageRights, updateModelsUsageRights, DialogPreview, withReactElement) ->

  ManageUsageRightsModal =
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
          @setRestrictedAccess(@refs.restrictedSelection.extractFormValues())
        else
          $.flashError(I18n.t('There was an error setting usage rights.'))
        @props.closeModal()

      setUsageRights(@props.itemsToManage, usageRightValue, afterSet)

    setRestrictedAccess: (attributes) ->
      @props.itemsToManage.every (item) ->
        item.save({}, {attrs: attributes})

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
