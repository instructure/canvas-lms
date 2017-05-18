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
#
# Handles getting the status for a file.
#
define [
  'Backbone'
  'i18n!file_status'
  ], (Backbone, I18n) ->

  #
  # Returns an internationalized string describing the status of a file.
  #
  # model is a Backbone file model.
  #
  getFileStatus = (model) ->

    # Error handling to return an empty string should a Backbone model not
    # be provided, or if it is currently undefined/null.
    if (!model? || !(model instanceof Backbone.Model))
      return ''



    # Determine what the file status is
    status =
      published: !model.get('locked')
      restricted: !!model.get('lock_at') || !!model.get('unlock_at')
      hidden: !!model.get('hidden')


    if status.published && status.restricted
      I18n.t('restricted_status', "Available from %{from_date} until %{until_date}",from_date: $.datetimeString(model.get('unlock_at')), until_date: $.datetimeString(model.get('lock_at')) )
    else if status.published && status.hidden
      I18n.t('hidden_status', 'Hidden. Available with a link')
    else if status.published
      I18n.t('published_status', 'Published')
    else
      I18n.t('unpublished_status', 'Unpublished')
