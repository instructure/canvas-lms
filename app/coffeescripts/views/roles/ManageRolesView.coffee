#
# Copyright (C) 2012 - present Instructure, Inc.
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
  'i18n!roles'
  'jquery'
  'underscore'
  'Backbone'
  'jst/roles/manageRoles'
  './PermissionButtonView'
  './RoleHeaderView'
  'str/htmlEscape'
], (I18n, $, _, Backbone, template, PermissionButtonView, RoleHeaderView, htmlEscape) ->
  class ManageRolesView extends Backbone.View
    template: template
    className: 'manage-roles-table'

    @optionProperty 'base_role_types'

    # Method Summary
    #   When a new Role is added/removed from the collection, re-draw the table.
    initialize: -> 
      super
      @permission_groups = @options.permission_groups if @options.permission_groups
      @collection.on 'add', @renderTable
      @collection.on 'remove', @renderTable

    # Method Summary
    #   Gets called after this backbone view has
    #   been rendered. For each permission in the 
    #   permission list, it will add a new 
    #   permission select box for each role in the roles
    #   collection. In this way, we are drawing the
    #   whole table row by row since html doesn't
    #   support drawing column by column. 
    # @api custom backbone
    afterRender: ->
      @renderTable()

    # Method Summary
    #   The table has two parts. A header and the tbody part. The header 
    #   has some functionality to do with deleting a role so contains its
    #   own logic. renderHeader gets called when renderTable gets 
    #   called, which should get called when role is added or removed.
    # @api private
    renderHeader: -> 
      @$el.find('thead tr').html "<th>#{htmlEscape(I18n.t('permissions', 'Permissions'))}</th>"

      @collection.each (role) =>
        roleHeaderView = new RoleHeaderView
          model: role
          base_role_types: @base_role_types

        @$el.find('thead tr').append roleHeaderView.render().el

    # Method Summary
    #   Creates the permission table by drawing it all at once.
    #   This is necessary because html tables only support 
    #   drawing a table via rows instead of columns and we are 
    #   representing our data in coloumns. works by bring in
    #   permission_groups, drawing the main group headers then
    #   for each main group of permissions, drawing each one of
    #   those permissions rows by iterating over each role in the
    #   collection and drawing a select box for each role. The 
    #   permissions_group object looks like this. 
    #
    #     permission_groups = [
    #       {
    #         group_name:"Parent label"
    #         group_permissions: [
    #           {
    #               label: "title"
    #               permission_name: "some_property"
    #           }
    #           {
    #               label: "title again"
    #               permission_name: "some_property_again"
    #           }
    #         
    #           ]
    #       }
    #       {
    #         group_name:"Parent label 2"
    #         group_permissions: [
    #               label: "title 2"
    #               permission_name: "some_other_property_2"
    #           ]
    #       }
    #     ]
    #
    # Steps: 1. Draw group header
    #        2. Draw permission label
    #        3. Draw each select box from the collection of roles.
    # @api private
    renderTable: => 
      @renderHeader()
      @$el.find('tbody').html '' # Clear tbody in case it gets re-drawing.

      _.each @permission_groups, (permission_group) => 
        # Add the headers to the group
        permission_group_header_html = """
                                    <tr class="toolbar">
                                      <th colspan="#{htmlEscape(@collection.length + 1)}">#{htmlEscape(permission_group.group_name.toUpperCase())}</th>
                                    </tr>
                                  """

        @$el.find('tbody').append permission_group_header_html

        # Add each permission item.
        _.each permission_group.group_permissions, (permission_row) => 

          permission_row_html = """
                            <tr>
                              <th role="rowheader">#{htmlEscape(permission_row.label)}</th>
                            </tr>
                           """

          @$el.find('tbody').append permission_row_html

          @collection.each (role) => 
            permissionButtonView = new PermissionButtonView
                                     model: role
                                     permission_name: permission_row.permission_name

            @$el.find("tr")
                .last()
                .append permissionButtonView.render().el
