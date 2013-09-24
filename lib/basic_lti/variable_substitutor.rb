#
# Copyright (C) 2013 Instructure, Inc.
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
module BasicLTI
class VariableSubstitutor

  def initialize(tool_launch)
    @launch = tool_launch
  end


  # modifies the launch hash by substituting all the known variables
  # if a variable is not supported or not allowed the value will not change
  def substitute!
    @launch.hash.each do |key, val|
      if val.to_s.starts_with? '$'
        method_name = "sub_#{var_to_method(val)}"
        if self.respond_to?(method_name, true)
          if new_val = self.send(method_name)
            @launch.hash[key] = new_val
          end
        end
      end
    end
  end

  private

  def var_to_method(var_name)
    var_name.gsub('$', '').gsub('.', '_')
  end


  ### These should return the value of substituting the variable the method is named for
  ### The method name should be prefixed with 'sub_' and have the same name as the variable except change all . to _
  ### For Example, to support substituting $Person.name.full, create a method called sub_Person_name_full
  ### If appropriate, check permissions by using the @launch object to reference the user/course

  # $Person.name.full
  def sub_Person_name_full
    @launch.tool.include_name? ? @launch.user.name : nil
  end

  # $Person.name.family
  def sub_Person_name_family
    @launch.tool.include_name? ? @launch.user.last_name : nil
  end

  # $Person.name.given
  def sub_Person_name_given
    @launch.tool.include_name? ? @launch.user.first_name : nil
  end

  # $Person.address.timezone
  def sub_Person_address_timezone
    Time.zone.tzinfo.name
  end

  # returns the same LIS Role values as the default 'roles' parameter,
  # but for concluded enrollments
  # $Canvas.membership.concludedRoles
  def sub_Canvas_membership_concludedRoles
    @launch.user_data['concluded_role_types'] ? @launch.user_data['concluded_role_types'].join(',') : nil
  end

end
end