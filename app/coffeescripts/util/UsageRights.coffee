define [
  "i18n!usage.rights"
  "jquery"
  "react" # React.js
  "compiled/react_files/components/UsageRightsSelectBox" # Usage rights select boxes (React component)
  "compiled/str/splitAssetString" # For splitting up the context_asset_string
], (I18n, $, React, UsageRightsSelectBox, splitAssetString) ->
  class UsageRights
    @usageRightsRequired: false
    @getContext: ->
      context = splitAssetString(window.ENV.context_asset_string)
      contextType: context[0]
      contextId: context[1]

    @setFileUsageRights: (attachment) ->
      context = @getContext()
      if @usageRightsRequired and context.contextId and context.contextType is "courses" and @usageRightsFields
        attrs = @usageRightsFields.getValues()
        usageRightSelected = attrs.use_justification and attrs.use_justification isnt "choose"
        if usageRightSelected
          $.ajax
            url: "/api/v1/courses/#{context.contextId}/usage_rights"
            type: "PUT"
            data:
              file_ids: [attachment.id]
              publish: usageRightSelected
              usage_rights:
                use_justification: attrs.use_justification
                legal_copyright: attrs.copyright
                license: attrs.cc_license

            success: (resp) ->
              $.flashMessage I18n.t("%{filename} has been published with the following usage right: %{usage_right}",
                filename: attachment.display_name
                usage_right: resp.license_name
              )

            error: (responseText, jqXhr, responseCode) ->
              $.flashError I18n.t("An error occurred when setting the usage right for %{filename}",
                filename: attachment.display_name
              )

    @render: (elementId = "") ->
      $element = $(elementId)
      @usageRightsRequired = $element.data('usageRightsRequired')

      if @usageRightsRequired
        context = @getContext()

        @usageRightsFields = React.renderComponent(UsageRightsSelectBox(
          use_justification: "choose"
          showMessage: true
          contextType: context.contextType
          contextId: context.contextId
          afterChooseBlur: -> $('.uploadFileBtn')[0]
        ), $element[0])