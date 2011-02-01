#
# Copyright (C) 2011 Instructure, Inc.
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

module HasCustomFieldsHelper
  # Note we're not using this yet -- Canvas only sets custom fields via the API
  # so far.
  def custom_field_form_element(custom_field, form, opts = {})
    cfv = form.object.get_custom_field_value(custom_field)
    # Need to figure out how to make this play nice with form.fields_for, it'd
    # be a lot less crufty.
    case custom_field.field_type
    when 'boolean'
      hidden_field_tag("#{form.object_name}[set_custom_field_values][#{custom_field.id}][value]", "0") +
      check_box_tag("#{form.object_name}[set_custom_field_values][#{custom_field.id}][value]", "1", cfv.true?)
    else
      raise "Whoops, need to implement this"
    end
  end
end
