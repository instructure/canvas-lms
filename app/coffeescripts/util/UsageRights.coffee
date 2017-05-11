#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  "i18n!usage.rights"
  "jquery"
  "react"
  "react-dom"
  "jsx/files/UsageRightsSelectBox" # Usage rights select boxes (React component)
  "compiled/str/splitAssetString" # For splitting up the context_asset_string
], (I18n, $, React, ReactDOM, UsageRightsSelectBox, splitAssetString) ->
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

        @usageRightsFields = ReactDOM.render(React.createFactory(UsageRightsSelectBox)(
          use_justification: "choose"
          showMessage: true
          contextType: context.contextType
          contextId: context.contextId
          afterChooseBlur: -> $('.uploadFileBtn')[0]
        ), $element[0])
