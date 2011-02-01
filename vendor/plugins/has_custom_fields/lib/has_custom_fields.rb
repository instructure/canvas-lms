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

module HasCustomFields
  module ClassMethods
    # Define this model as having custom fields. This mixes in
    # HasCustomFields::InstanceMethods. For example, this will scope custom
    # fields both globally, and to the user's account:
    #
    #   class User < ActiveRecord::Base
    #     belongs_to :account
    #     has_custom_fields :scopes => [:account]
    #   end
    #
    #   class Account < ActiveRecord::Base
    #     scopes_custom_fields
    #   end
    #
    # Options:
    # * :scopes - An array of scopes to check for custom fields, beyond the
    #   global custom fields.
    def has_custom_fields(opts = {})
      class_inheritable_accessor :custom_fields_options
      opts[:scopes] = Array(opts[:scopes])
      self.custom_fields_options = opts

      has_many :custom_field_values,
        :as => :customized,
        :include => :custom_field,
        :dependent => :destroy,
        :autosave => true
      self.send :include, HasCustomFields::InstanceMethods
    end

    # Define this model as scoping custom fields for other models. See
    # has_custom_fields
    def scopes_custom_fields
      has_many :custom_fields,
        :as => :scoper,
        :dependent => :destroy
    end
  end

  # The methods available on an instance of a class that has_custom_fields
  module InstanceMethods
    # The available custom fields for this instance. Note this is per-instance,
    # because custom fields can be scoped to associations. So not all instances
    # of the same model will have the same custom fields available.
    def available_custom_fields
      # This is basically equivalent to, but does everything in one query:
      # # global custom fields for this type
      # fields = CustomField.scoped(:conditions => { :scoper_id => nil }).for_class(self.class)
      # # scoped custom fields for this type
      # fields +
      # self.class.custom_fields_options[:scopes].inject([]) do |a, scope|
      #   a + self.send(scope).custom_fields.for_class(self.class)
      # end
      conditions = ["scoper_id IS NULL"]
      self.class.custom_fields_options[:scopes].each do |scope|
        obj = self.send(scope)
        next unless obj
        conditions << "(scoper_type = '#{obj.class.base_class.name}' AND scoper_id = '#{obj.id}')"
      end
      CustomField.for_class(self.class).scoped(:conditions => conditions.join(" OR "))
    end

    # vals is a hash { custom_field_id => new_val }
    # Note custom fields can't reliably be set in the creation hash, because of
    # race conditions. For instance, if a User custom field is scoped to a
    # certain Account, User.create(:account_id => 1, :set_custom_field_values =>
    # { ... }) might try to set the custom fields before the account id, and the
    # field would appear to be unavailable.
    def set_custom_field_values=(vals)
      custom_fields = available_custom_fields.to_a
      vals.each do |field_id, params|
        custom_field = custom_fields.find { |f| f.id == field_id.to_i || f.name == field_id }
        next unless custom_field
        cfv = get_custom_field_value(custom_field)
        cfv.value = params['value']
      end
    end

    # Returns the CustomFieldValue for the name [String] or field [CustomField]
    # passed in. Creates (but doesn't save) the value if necessary.
    def get_custom_field_value(name_or_field)
      return nil unless name_or_field

      custom_field = case name_or_field
        when String
          available_custom_fields.find_by_name(name_or_field)
        when CustomField
          name_or_field
        else
          raise ArgumentError
        end
      return nil unless custom_field

      custom_field_values.find_by_custom_field_id(custom_field.id) ||
        custom_field_values.build(:custom_field => custom_field)
    end
  end
end
