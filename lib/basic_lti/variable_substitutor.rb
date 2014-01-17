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

require 'lib/basic_lti/variable_substitution/canvas'
require 'lib/basic_lti/variable_substitution/person'

module BasicLTI
  class VariableSubstitutor

    def initialize(tool_launch)
      @launch = tool_launch
      @substitutors = {}
    end

    def method_missing(method, *args, &block)
      name = method.to_s
      if name[0] == '$'
        klass = var_to_class(name)

        #Create or use the appropriate variable substitutor
        @substitutors[klass] ||= klass.new(@launch)
        return @substitutors[klass].send(var_to_method_name(name))
      else
        super
      end
    end

    # modifies the launch hash by substituting all the known variables
    # if a variable is not supported or not allowed the value will not change
    def substitute!
      @launch.hash.each do |key, val|
        if val.to_s.starts_with? '$'
          if valid_method?(val) && new_val = self.send(val)
            @launch.hash[key] = new_val
          end
        end
      end
    end

    ### Substitution methods should be in the BasicLTI::VariableSubstitution namespace
    ### and then further namespaced by their variable namespaces.  For example,
    ### $Canvas.membership.concludedRoles should refer to the concluded_roles method
    ### of the BasicLTI::VariableSubstitution::Canvas::Membership class.  All module
    ### names will be titlized and all method names will be underscored to follow ruby
    ### naming conventions.
    ###
    ### Additionally, all methods will be called in the context
    ### of the BasicLTI::VariableSubstitutor class to give access to this context
    ### and launch information
    ###
    ### If the launch cannot produce the substitution value, the function should
    ### return nil.  VariableSubstitutor checks for nil return values to handle
    ### invalid substitution parameters.  If you actually need to substitute an
    ### empty value, return an empty string ("") .
    ###
    ### See the classes in the lib/basic_lti/variable_substitution folder for more examples.

    private

    # This method splits out the name of the class and prepends the namespace for
    # variable substitution.  For example, $Canvas.enrollment.enrollment_state,
    # would be converted to BasicLTI::VariableSubstitution::Canvas::Enrollment
    def var_to_class(var)
      names = var[1..-1].split('.')[0...-1].map{|ns| ns.titleize}
      names.inject(::BasicLTI::VariableSubstitution) do |constant, name|
        constant.const_get(name)
      end
    end

    def var_to_method_name(var)
      var.split('.').last.underscore.to_sym
    end

    def valid_method?(var)
      begin
        valid_methods = var_to_class(var).public_instance_methods(false)
      rescue NameError
        valid_methods = []
      end
      valid_methods.include?(var_to_method_name(var))
    end
  end
end