#
# Copyright (C) 2014 Instructure, Inc.
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

require "active_polymorph"

describe ActiveRecord do

  describe ActiveRecord::Base do
    it "should respond to polymorphic_names" do
      ActiveRecord::Base.respond_to?(:polymorphic_names).should be_true
    end

    it "should by default return its own class" do
      class SomeClass < ActiveRecord::Base; end
      SomeClass.polymorphic_names.should == ["SomeClass"]
    end

    it "should return defined polymorphic names" do
      class SomeClass < ActiveRecord::Base
        def self.polymorphic_names
          [self.base_class.name, "SomeOtherClass"]
        end
      end
      SomeClass.polymorphic_names.sort.should == ["SomeClass", "SomeOtherClass"]
    end
  end

  describe ActiveRecord::Associations do
    before(:all) do
      ActiveRecord::Base.establish_connection(
        :adapter => 'sqlite3',
        :database => ':memory:'
      )

      ActiveRecord::Schema.define do
        create_table :things, :force => true do |t|
          t.integer :context_id
          t.string :context_type
        end

        create_table :normal_contexts, :force => true do |t|
          t.string :something_meaningful
        end

      end

      class Thing < ActiveRecord::Base
        belongs_to :context, :polymorphic => true
      end

      class NormalContext < ActiveRecord::Base
        has_many :things, :as => :context

        def self.polymorphic_names
          [self.base_class.name, "Namespaced::ParaNormalContext"]
        end
      end

      module Namespaced
        class ParaNormalContext < ::ActiveRecord::Base
          self.table_name = "normal_contexts"
          has_many :things, :as => :context

          def self.polymorphic_names
            [self.base_class.name, "NormalContext"]
          end
        end
      end
    end

    describe "HasManyAssociation" do
      before(:each) do
        @normal_context = NormalContext.create!(something_meaningful: "This is a holy scripture for a small tribe in Paraguay")
        @namespaced_context = Namespaced::ParaNormalContext.find(@normal_context.id)
        @thing_a = @normal_context.things.create!
        @thing_b = @namespaced_context.things.create!
      end

      it "should find records bearing polymorphic names" do
        @normal_context.reload.things.should == [@thing_a,@thing_b]
        @namespaced_context.reload.things.should == [@thing_a,@thing_b]
      end

      it "should not find records not bearing polymorphic names" do
        ActiveRecord::Base.connection.execute("UPDATE things SET context_type = 'NotReallyAThing' WHERE id =  #{@thing_a.id}")
        @normal_context.reload.things.should == [@thing_b]
        @namespaced_context.reload.things.should == [@thing_b]
      end


      it "should use polymorphic names in count queries" do
        @normal_context.reload.things.count.should == 2
        ActiveRecord::Base.connection.execute("UPDATE things SET context_type = 'NotReallyAThing' WHERE id =  #{@thing_a.id}")
        @normal_context.reload.things.count.should == 1
      end

      it "should prefer custom finder_sql if provided" do
        NormalContext.class_eval do 
          has_many :things, :as => :context, :finder_sql =>
            proc{ "SELECT * FROM things WHERE context_id = #{id} AND context_type = '#{self.class.base_class.name}'" }
        end

        @namespaced_context.reload.things.should == [@thing_a, @thing_b]
        @normal_context.reload.things.should == [@thing_a]
      end

      it "should prefer custom counter_sql if provided" do
        NormalContext.class_eval do 
          has_many :things, :as => :context, :counter_sql =>
            proc{ "SELECT COUNT(*) FROM things WHERE context_id = #{id} AND context_type = '#{self.class.base_class.name}'" }
        end

        @namespaced_context.reload.things.count.should == 2
        @normal_context.reload.things.count.should == 1
      end

      it "should count/find correctly with additional where/find scopes" do
        @normal_context.things.find(@thing_a.id).should == @thing_a
        @normal_context.things.where(context_type: "Namespaced::ParaNormalContext").first.should == @thing_b
        scope = @normal_context.things.where(context_type: "Namespaced::ParaNormalContext")
        scope.count.should == 1
        scope.should == [@thing_b]
      end

      it "should work with pluck" do
        @normal_context.things.pluck(:id).should == [@thing_a.id, @thing_b.id]
      end

      it "should work with build_associations" do
        thing_c = @normal_context.things.build
        thing_c.save!
        @normal_context.reload.things.should == [@thing_a, @thing_b, thing_c]
      end

    end
  end
end
