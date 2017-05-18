#
# Copyright (C) 2013 - present Instructure, Inc.
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
  'Backbone',
  'jst/gradezilla/checkbox_view'
], ({View}, template) ->

  class CheckboxView extends View

    tagName: 'label'

    className: 'checkbox-view'

    @optionProperty 'color'

    @optionProperty 'label'

    checked: true

    template: template

    events:
      'click': 'onClick'

    onClick: (e) ->
      e.preventDefault()
      @toggleState()

    toggleState: ->
      @checked = !@checked
      @trigger('togglestate', @checked)
      @render()

    toJSON: ->
      json =
        checked : @checked.toString()
        color   : if @checked then @options.color else 'none'
        label   : @options.label
