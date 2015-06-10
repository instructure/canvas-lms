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

require 'spec_helper'
require 'mocha/api'

describe ActiveSupport::Callbacks::Suspension do
  before do
    @rails2 = rails2 = ActiveSupport::VERSION::STRING < '3'

    @class = Class.new do
      include ActiveSupport::Callbacks
      include ActiveSupport::Callbacks::Suspension

      def validate; end

      def persist; end

      def publish; end

      if rails2
        define_callbacks :before_save, :after_save, :before_update
        before_save :validate
        after_save :publish
        before_update :validate

        def save
          return unless run_callbacks(:before_save) { |result, _| result == false }
          persist
          run_callbacks(:after_save) { |result, _| result == false }
        end

        def update
          return unless run_callbacks(:before_update) { |result, _| result == false }
          persist
        end
      else
        define_callbacks :save, :update
        set_callback :save, :before, :validate
        set_callback :save, :after, :publish
        set_callback :update, :before, :validate

        def save
          run_callbacks(:save) { persist }
        end

        def update
          run_callbacks(:update) { persist }
        end
      end
    end
    @instance = @class.new
  end

  describe "suspend_callbacks" do
    it "should suspend all callbacks by default" do
      @instance.expects(:validate).never
      @instance.expects(:publish).never
      @instance.suspend_callbacks{ @instance.save }
    end

    it "should treat suspended callbacks as successful" do
      @instance.expects(:persist).once
      @instance.suspend_callbacks{ @instance.save }
    end

    it "should only suspend given callbacks" do
      @instance.expects(:validate).never
      @instance.expects(:publish).once
      @instance.suspend_callbacks(:validate) { @instance.save }
    end

    it "should only suspend callbacks of the given kind" do
      @instance.expects(:validate).once
      if @rails2
        @instance.suspend_callbacks(kind: :before_save) { @instance.update }
      else
        @instance.suspend_callbacks(kind: :save) { @instance.update }
      end
    end

    unless @rails2
      it "should only suspend callbacks of the given type" do
        @instance.expects(:validate).never
        @instance.expects(:publish).once
        @instance.suspend_callbacks(type: :before) { @instance.save }
      end
    end
  end

  describe "nesting" do
    it "should combine suspensions from various levels" do
      @instance.expects(:validate).never
      @instance.expects(:publish).never
      @instance.suspend_callbacks(:validate) do
        @instance.suspend_callbacks(:publish) do
          @instance.save
        end
      end
    end

    it "should restore correct subset of suspensions after leaving block" do
      @instance.expects(:validate).never
      @instance.expects(:publish).once
      @instance.suspend_callbacks(:validate) do
        @instance.suspend_callbacks(:publish) do
          @instance.save
        end
        @instance.save
      end
    end
  end

  describe "inheritance" do
    it "should apply suspensions from the class to instances" do
      @instance.expects(:validate).never
      @instance.expects(:publish).never
      @class.suspend_callbacks{ @instance.save }
    end

    it "should apply suspensions from a superclass to instances of a subclass" do
      subclass = Class.new(@class)
      instance = subclass.new
      instance.expects(:validate).never
      instance.expects(:publish).never
      @class.suspend_callbacks{ instance.save }
    end

    it "should combine suspensions from various levels" do
      subclass = Class.new(@class)
      instance = subclass.new
      instance.expects(:validate).never
      instance.expects(:publish).never
      # only suspends :validate from save
      instance.suspend_callbacks(:validate, kind: (@rails2 ? :before_save : :save)) do
        # only suspends :publish
        subclass.suspend_callbacks(:publish) do
          # only suspends :validate from update
          @class.suspend_callbacks(kind: (@rails2 ? :before_update : :update)) do
            # trigger (absent suspensions) all three
            instance.save
            instance.update
          end
        end
      end
    end
  end
end
