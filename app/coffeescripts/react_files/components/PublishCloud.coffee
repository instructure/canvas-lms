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
  'jquery'
  'react'
  'prop-types'
  'i18n!broccoli_cloud'
  '../../models/FilesystemObject'
  '../modules/customPropTypes'
  '../../jquery.rails_flash_notifications'
], ($, React, PropTypes, I18n, FilesystemObject, customPropTypes) ->

  PublishCloud =
    displayName: 'PublishCloud'

    propTypes:
      togglePublishClassOn: PropTypes.object
      model: customPropTypes.filesystemObject
      userCanManageFilesForContext: PropTypes.bool.isRequired
      fileName: PropTypes.string

    # == React Functions == #
    getInitialState: -> @extractStateFromModel( @props.model )

    componentDidMount: -> @updatePublishClassElements() if @props.togglePublishClassOn
    componentDidUpdate: -> @updatePublishClassElements() if @props.togglePublishClassOn

    componentWillMount: ->
      setState = (model) => @setState(@extractStateFromModel( model ))
      @props.model.on('change', setState, this)

    componentWillUnmount: ->
      @props.model.off(null, null, this)

    updatePublishClassElements: ->
      if @state.published
        @props.togglePublishClassOn.classList.add('ig-published')
      else
        @props.togglePublishClassOn.classList.remove('ig-published')

    getRestrictedText: ->
      if @props.model.get('unlock_at') and @props.model.get('lock_at')
        I18n.t("Available after %{unlock_at} until %{lock_at}", unlock_at: $.datetimeString(@props.model.get('unlock_at')), lock_at: $.datetimeString(@props.model.get('lock_at')))
      else if @props.model.get('unlock_at') and not @props.model.get('lock_at')
        I18n.t("Available after %{unlock_at}", unlock_at: $.datetimeString(@props.model.get('unlock_at')))
      else if not @props.model.get('unlock_at') and @props.model.get('lock_at')
        I18n.t("Available until %{lock_at}", lock_at: $.datetimeString(@props.model.get('lock_at')))

    # == Custom Functions == #

    # Function Summary
    # extractStateFromModel expects a backbone model wtih the follow attributes
    # * hidden, lock_at, unlock_at
    #
    # It takes those attributes and returns an object that can be used to set the
    # components internal state
    #
    # returns object

    extractStateFromModel: (model) ->
      published: !model.get('locked')
      restricted: !!model.get('lock_at') || !!model.get('unlock_at')
      hidden: !!model.get('hidden')

    # Function Summary
    # Toggling always sets restricted state to false because we only
    # allow publishing/unpublishing in this component.

    togglePublishedState: ->
      @setState published: !@state.published, restricted: false, hidden: false
