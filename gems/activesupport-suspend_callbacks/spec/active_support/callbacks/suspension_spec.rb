# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require "spec_helper"

describe ActiveSupport::Callbacks::Suspension do
  before do
    @class = Class.new do
      include ActiveSupport::Callbacks
      include ActiveSupport::Callbacks::Suspension

      def validate; end

      def persist; end

      def publish; end

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
    @instance = @class.new
  end

  describe "suspend_callbacks" do
    it "suspends all callbacks by default" do
      expect(@instance).not_to receive(:validate)
      expect(@instance).not_to receive(:publish)
      @instance.suspend_callbacks { @instance.save }
    end

    it "treats suspended callbacks as successful" do
      expect(@instance).to receive(:persist).once
      @instance.suspend_callbacks { @instance.save }
    end

    it "only suspends given callbacks" do
      expect(@instance).not_to receive(:validate)
      expect(@instance).to receive(:publish).once
      @instance.suspend_callbacks(:validate) { @instance.save }
    end

    it "only suspends callbacks of the given kind" do
      expect(@instance).to receive(:validate).once
      @instance.suspend_callbacks(kind: :save) { @instance.update }
    end

    it "only suspends callbacks of the given type" do
      expect(@instance).not_to receive(:validate)
      expect(@instance).to receive(:publish).once
      @instance.suspend_callbacks(type: :before) { @instance.save }
    end
  end

  describe "nesting" do
    it "combines suspensions from various levels" do
      expect(@instance).not_to receive(:validate)
      expect(@instance).not_to receive(:publish)
      @instance.suspend_callbacks(:validate) do
        @instance.suspend_callbacks(:publish) do
          @instance.save
        end
      end
    end

    it "restores correct subset of suspensions after leaving block" do
      expect(@instance).not_to receive(:validate)
      expect(@instance).to receive(:publish).once
      @instance.suspend_callbacks(:validate) do
        @instance.suspend_callbacks(:publish) do
          @instance.save
        end
        @instance.save
      end
    end
  end

  describe "inheritance" do
    it "applies suspensions from the class to instances" do
      expect(@instance).not_to receive(:validate)
      expect(@instance).not_to receive(:publish)
      @class.suspend_callbacks { @instance.save }
    end

    it "applies suspensions from a superclass to instances of a subclass" do
      subclass = Class.new(@class)
      instance = subclass.new
      expect(instance).not_to receive(:validate)
      expect(instance).not_to receive(:publish)
      @class.suspend_callbacks { instance.save }
    end

    it "combines suspensions from various levels" do
      subclass = Class.new(@class)
      instance = subclass.new
      expect(instance).not_to receive(:validate)
      expect(instance).not_to receive(:publish)
      # only suspends :validate from save
      instance.suspend_callbacks(:validate, kind: :save) do
        # only suspends :publish
        subclass.suspend_callbacks(:publish) do
          # only suspends :validate from update
          @class.suspend_callbacks(kind: :update) do
            # trigger (absent suspensions) all three
            instance.save
            instance.update
          end
        end
      end
    end

    it "keeps class suspensions independent per thread" do
      expect(@instance).not_to receive(:validate)
      expect(@instance).to receive(:publish).once

      @class.suspend_callbacks(:validate) do
        Thread.new do
          @instance2 = @class.new
          expect(@instance2).to receive(:validate).once
          expect(@instance2).to receive(:publish).once
          @instance2.save
        end.join

        @instance.save
      end
    end
  end
end
