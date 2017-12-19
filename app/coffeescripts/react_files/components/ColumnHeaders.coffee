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
  'i18n!react_files'
  'underscore'
  'react'
  'prop-types'
  '../../fn/preventDefault'
], (I18n, _, React, PropTypes, preventDefault) ->

  columns = [
    displayName: I18n.t('name', 'Name')
    property: 'name'
    className: 'ef-name-col'
  ,
    displayNameShort: I18n.t('created_at_short', 'Created')
    displayName: I18n.t('created_at', 'Date Created')
    property: 'created_at'
    className: 'ef-date-created-col'
  ,
    displayNameShort: I18n.t('updated_at_short', 'Modified')
    displayName: I18n.t('updated_at', 'Date Modified')
    property: 'modified_at'
    className: 'ef-date-modified-col'
  ,
    displayName: I18n.t('modified_by', 'Modified By')
    className: 'ef-modified-by-col'
    property: 'user'
  ,
    displayName: I18n.t('size', 'Size')
    property: 'size'
    className: 'ef-size-col'
  ,
    displayName: I18n.t('Usage Rights')
    property: 'usage_rights'
    className: 'ef-usage-rights-col'
  ]

  ColumnHeaders =
    displayName: 'ColumnHeaders'

    columns: columns

    propTypes:
      query: PropTypes.object.isRequired
      toggleAllSelected: PropTypes.func.isRequired
      areAllItemsSelected: PropTypes.func.isRequired

    getInitialState: ->
      return {
        hideToggleAll: true
      }

    queryParamsFor: (query, property) ->
      order = if ((query.sort || 'name') is property) and (query.order is 'desc')
        'asc'
      else
        'desc'
      _.defaults({sort: property, order: order}, query)

