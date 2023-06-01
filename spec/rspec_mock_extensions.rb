# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

# allows setting up mocks/stubs that will be automatically applied any time
# this AR instance is instantiated, through find or whatever
# the record must be saved before calling any_instantiation, so that it has an id
module RspecMockAnyInstantiation
  module ClassMethods
    def reset_any_instantiation!
      @@any_instantiation = {}
    end

    def add_any_instantiation(ar_obj)
      raise(ArgumentError, "need to save first") if ar_obj.new_record?

      @@any_instantiation[[ar_obj.class.base_class, ar_obj.id]] = ar_obj
      # calling any_instantiation is likely to be because you're stubbing it,
      # and to later be cached inadvertently from code that *thinks* it
      # has a non-stubbed object. So let it dump, but not load (i.e.
      # the MemoryStore and NilStore dumps that are just for testing,
      # but just discard the result of dump)
      def ar_obj.marshal_dump
        nil
      end
      # no marshal_load; will raise an exception on load
      ar_obj
    end

    def instantiate(record, column_types = {}, &)
      if (obj = @@any_instantiation[[base_class, record["id"].to_i]])
        obj
      else
        super
      end
    end

    def instantiate_instance_of(klass, record, column_types = {}, &)
      if (obj = @@any_instantiation[[klass, record["id"].to_i]])
        obj
      else
        super
      end
    end
  end

  def allow_any_instantiation_of(ar_object)
    ActiveRecord::Base.add_any_instantiation(ar_object)
    allow(ar_object)
  end

  def expect_any_instantiation_of(ar_object)
    ActiveRecord::Base.add_any_instantiation(ar_object)
    expect(ar_object) # rubocop:disable RSpec/VoidExpect we return the expectation object to the caller
  end
end
ActiveRecord::Base.singleton_class.prepend(RspecMockAnyInstantiation::ClassMethods)
RSpec::Mocks::ExampleMethods.include(RspecMockAnyInstantiation)
ActiveRecord::Base.reset_any_instantiation!
