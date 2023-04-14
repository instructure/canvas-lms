# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe RootAccountResolver do
  let(:minimal_active_record) do
    Class.new do
      extend ActiveModel::Callbacks
      define_model_callbacks :save

      attr_accessor :root_account_id

      def save
        run_callbacks :save
      end

      def attributes
        { "root_account_id" => root_account_id }
      end

      def has_attribute?(key)
        attributes.key?(key)
      end

      def self.belongs_to(relation, **opts); end
    end
  end
  let(:test_class) do
    Class.new(minimal_active_record) do
      extend RootAccountResolver

      def initialize(root_account_id)
        super()
        @root_account_id = root_account_id
      end

      def knower_of_account_1337
        Struct.new(:root_account_id).new(1337)
      end
    end
  end

  describe "resolution via member" do
    before do
      test_class.resolves_root_account through: :knower_of_account_1337
    end

    it "assigns it on save if it is not set" do
      subject = test_class.new(nil)

      expect do
        subject.save
      end.to change {
        subject.root_account_id
      }.from(nil).to(1337)
    end

    it "preserves it on save if it was already set" do
      subject = test_class.new(666)

      expect do
        subject.save
      end.not_to change {
        subject.root_account_id
      }
    end
  end

  describe "resolution via proc" do
    before do
      test_class.resolves_root_account through: proc { 9000 }
    end

    it "assigns it on save if it is not set" do
      subject = test_class.new(nil)

      expect do
        subject.save
      end.to change {
        subject.root_account_id
      }.from(nil).to(9000)
    end

    it "preserves it on save if it was already set" do
      subject = test_class.new(666)

      expect do
        subject.save
      end.not_to change {
        subject.root_account_id
      }
    end
  end
end
