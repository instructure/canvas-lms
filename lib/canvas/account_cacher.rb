# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

module Canvas
  module AccountCacher
    class CacheAccountOnAssociation < ::ActiveRecord::Associations::BelongsToAssociation
      def find_target
        key = ["account2", owner.attribute(reflection.foreign_key)].cache_key
        RequestCache.cache([Switchman::Shard.current.id, key].cache_key) { Rails.cache.fetch(key) { super } }
      end
    end

    class CacheAccountOnPolymorphicAssociation < ::ActiveRecord::Associations::BelongsToPolymorphicAssociation
      def find_target
        return super unless klass == Account

        key = ["account", owner.attribute(reflection.foreign_key)].cache_key
        RequestCache.cache([Switchman::Shard.current.id, key].cache_key) { Rails.cache.fetch(key) { super } }
      end
    end

    module ExtendAccountReflection
      def association_class
        CacheAccountOnAssociation
      end
    end

    module ExtendPolymorphicAccountReflection
      def association_class
        CacheAccountOnPolymorphicAssociation
      end
    end

    def self.apply_to_reflections(klass)
      klass.reflections.each do |(name, r)|
        next unless r.macro == :belongs_to
        next if name == "root_account"

        if r.options[:polymorphic]
          next unless klass.canonicalize_polymorph_list(r.options[:polymorphic]).map(&:last).include?("Account")
        else
          next unless r.class_name == "Account"
        end

        next if [Canvas::RootAccountCacher::ExtendRootAccountReflection,
                 ExtendAccountReflection,
                 ExtendPolymorphicAccountReflection].include?(r.association_class)

        r.extend(r.options[:polymorphic] ? ExtendPolymorphicAccountReflection : ExtendAccountReflection)

        next unless klass.reflections.key?("root_account")

        m = Module.new
        polymorphic_condition = "#{r.foreign_type} == 'Account' && " if r.options[:polymorphic]
        m.module_eval <<~RUBY, __FILE__, __LINE__ + 1
          def #{name}
            return root_account if !association(#{r.name.to_sym.inspect}).loaded? && #{polymorphic_condition}root_account_id && #{r.foreign_key} == root_account_id
            super
          end
        RUBY
        klass.include(m)
      end
    end
  end
end
