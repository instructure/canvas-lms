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
  module RootAccountCacher
    class CacheRootAccountOnAssociation < ActiveRecord::Associations::BelongsToAssociation
      def find_target
        target_id = owner._read_attribute(reflection.foreign_key)
        key = Switchman::Shard.default.activate { ["root_account", target_id].cache_key }
        return RequestCache.cache(key) { Account.find_cached(target_id) }
      end
    end

    module ExtendRootAccountReflection
      def association_class
        CacheRootAccountOnAssociation
      end
    end


    def self.included(klass)
      if (r = klass.reflections['root_account'])
        r.extend(ExtendRootAccountReflection)
      else
        (r = klass.reflections['account']).extend(ExtendRootAccountReflection)
      end
      m = Module.new

      m.module_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{r.name}
          return Account.current_domain_root_account if !association(#{r.name.to_sym.inspect}).loaded? && #{r.foreign_key} == Account.current_domain_root_account&.id
          return super
        end
      RUBY
      klass.include(m)  
    end
  end
end
