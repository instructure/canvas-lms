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
  'i18n!gradezilla'
  'Backbone'
  '../../gradezilla/OutcomeGradebookGrid'
  'jst/gradezilla/header_filter'
], (I18n, {View}, Grid, template) ->

  class HeaderFilterView extends View

    className: 'text-right'

    template: template

    labels:
      average: I18n.t('course_average', 'Course average')
      median: I18n.t('course_median', 'Course median')

    events:
      'click li a': 'onClick'

    @optionProperty 'grid'

    @optionProperty 'redrawFn'

    onClick: (e) ->
      e.preventDefault()
      e.stopPropagation()
      key = e.target.getAttribute('data-method')
      @closeMenu()
      @updateLabel(key)
      @recalculateHeader(key)

    closeMenu: ->
      @$el.find('.al-trigger')
        .data('kyleMenu')
        .close()

    updateLabel: (key) ->
      @$('.current-label').text(@labels[key])

    recalculateHeader: (key) ->
      key = 'mean' if key is 'average'
      @redrawFn(@grid, key)
