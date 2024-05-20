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

describe NewQuizzesFeaturesHelper do
  include NewQuizzesFeaturesHelper

  before :once do
    course_with_student(active_all: true)
    @context = @course
  end

  describe "#new_quizzes_import_enabled?" do
    it "is false when new quizzes is disabled" do
      expect(new_quizzes_import_enabled?).to be false
    end

    it "is false when new_quizzes enabled, but importing disabled" do
      allow(@context.root_account).to receive(:feature_allowed?).with(:quizzes_next).and_return(true)
      expect(new_quizzes_import_enabled?).to be false
    end

    it "is false when new_quizzes disabled" do
      @context.root_account.enable_feature!(:quizzes_next)
      expect(new_quizzes_import_enabled?).to be false
    end

    it "is false when new_quizzes disabled and allowed" do
      allow(@course).to receive(:feature_allowed?).with(:quizzes_next).and_return(true)
      allow(@course).to receive(:feature_enabled?).with(:quizzes_next).and_return(false)
      expect(new_quizzes_import_enabled?).to be false
    end

    it "is true when new_quizzes enabled" do
      allow(@course).to receive(:feature_allowed?).with(:quizzes_next).and_return(false)
      allow(@course).to receive(:feature_enabled?).with(:quizzes_next).and_return(true)
      expect(new_quizzes_import_enabled?).to be true
    end
  end

  describe "#new_quizzes_migration_enabled?" do
    it "is false when new quizzes is disabled" do
      expect(new_quizzes_migration_enabled?).to be false
    end

    it "is false when new_quizzes enabled, but importing disabled" do
      allow(@context.root_account).to receive(:feature_allowed?).with(:quizzes_next).and_return(true)
      expect(new_quizzes_migration_enabled?).to be false
    end

    it "is false when new_quizzes disabled, but importing enabled" do
      @context.root_account.enable_feature!(:new_quizzes_migration)
      expect(new_quizzes_migration_enabled?).to be false
    end

    it "is true when new_quizzes enabled, and importing enabled" do
      allow(@context.root_account).to receive(:feature_allowed?).with(:quizzes_next).and_return(true)
      @context.root_account.enable_feature!(:new_quizzes_migration)
      expect(new_quizzes_migration_enabled?).to be true
    end
  end

  describe "#new_quizzes_migration_default" do
    it "is false when default is disabled, and migration not required" do
      expect(new_quizzes_migration_default).to be false
    end

    it "is true when default is enabled" do
      @context.root_account.enable_feature!(:migrate_to_new_quizzes_by_default)
      expect(new_quizzes_migration_default).to be true
    end

    it "is true when migration_required" do
      @context.root_account.enable_feature!(:require_migration_to_new_quizzes)
      expect(new_quizzes_migration_default).to be true
    end
  end

  describe "#new_quizzes_migration_required" do
    it "is false when default is disabled, and migration not required" do
      expect(new_quizzes_require_migration?).to be false
    end

    it "is true when default is enabled" do
      @context.root_account.enable_feature!(:require_migration_to_new_quizzes)
      expect(new_quizzes_require_migration?).to be true
    end
  end

  describe "#new_quizzes_navigation_placements_enabled" do
    before do
      allow(@context).to receive(:feature_enabled?).with(:quizzes_next).and_return(true)
      Account.site_admin.enable_feature!(:new_quizzes_account_course_level_item_banks)
    end

    it "is true when new_quizzes_account_course_level_item_banks and quizzes_next are true" do
      expect(new_quizzes_navigation_placements_enabled?).to be true
    end

    it "is false when new_quizzes_account_course_level_item_banks is disabled" do
      Account.site_admin.disable_feature!(:new_quizzes_account_course_level_item_banks)
      expect(new_quizzes_navigation_placements_enabled?).to be false
    end

    it "is false when quizzes_next is disabled" do
      allow(@context).to receive(:feature_enabled?).with(:quizzes_next).and_return(false)
      expect(new_quizzes_navigation_placements_enabled?).to be false
    end

    it "accepts a context" do
      fake_context = Course.create(name: "fake context")
      fake_context.disable_feature!(:quizzes_next)
      expect(new_quizzes_navigation_placements_enabled?(fake_context)).to be false
    end
  end

  describe "#new_quizzes_bank_migrations_enabled?" do
    before do
      allow(@context).to receive(:feature_enabled?).with(:quizzes_next).and_return(true)
      allow(@context.root_account).to receive(:feature_enabled?).with(:new_quizzes_migration).and_return(true)
      Account.site_admin.enable_feature!(:new_quizzes_bank_migrations)
    end

    it "returns true when new_quizzes_bank_migrations, new_quizzes_migration and quizzes_next are true" do
      expect(new_quizzes_bank_migrations_enabled?).to be true
    end

    it "returns false when new_quizzes_bank_migrations is disabled" do
      Account.site_admin.disable_feature!(:new_quizzes_bank_migrations)
      expect(new_quizzes_bank_migrations_enabled?).to be false
    end

    it "returns false when quizzes_next is disabled" do
      allow(@context).to receive(:feature_enabled?).with(:quizzes_next).and_return(false)
      expect(new_quizzes_bank_migrations_enabled?).to be false
    end

    it "returns false when new_quizzes_migration is disabled" do
      allow(@context.root_account).to receive(:feature_enabled?).with(:new_quizzes_migration).and_return(false)
      expect(new_quizzes_bank_migrations_enabled?).to be false
    end
  end

  describe "#new_quizzes_by_default?" do
    before do
      allow(@context).to receive(:feature_enabled?).with(:quizzes_next).and_return(true)
      allow(@context).to receive(:feature_enabled?).with(:new_quizzes_by_default).and_return(true)
    end

    it "returns true when new_quizzes and new_quizzes_by_default are enabled" do
      expect(new_quizzes_by_default?).to be true
    end

    it "returns false when new_quizzes and new_quizzes_by_default are disabled" do
      allow(@context).to receive(:feature_enabled?).with(:quizzes_next).and_return(false)
      allow(@context).to receive(:feature_enabled?).with(:new_quizzes_by_default).and_return(false)
      expect(new_quizzes_by_default?).to be false
    end

    it "returns false when new_quizzes enabled and new_quizzes_by_default disabled" do
      allow(@context).to receive(:feature_enabled?).with(:new_quizzes_by_default).and_return(false)
      expect(new_quizzes_by_default?).to be false
    end

    it "returns false when new_quizzes disabled and new_quizzes_by_default enabled" do
      allow(@context).to receive(:feature_enabled?).with(:quizzes_next).and_return(false)
      expect(new_quizzes_by_default?).to be false
    end
  end

  describe "#disable_content_rewriting?" do
    def flag_state(value)
      Account.site_admin.set_feature_flag!(:new_quizzes_migrate_without_content_rewrite, value)
    end

    context "quizzes_next is true" do
      before do
        allow(@context).to receive(:feature_enabled?).with(:quizzes_next).and_return(true)
      end

      context "flag is off" do
        it "returns false" do
          flag_state Feature::STATE_OFF
          expect(NewQuizzesFeaturesHelper.disable_content_rewriting?(@context)).to be false
        end
      end

      context "flag is on" do
        it "returns true" do
          flag_state Feature::STATE_ON
          expect(NewQuizzesFeaturesHelper.disable_content_rewriting?(@context)).to be true
        end
      end
    end

    context "quizzes_next is false" do
      before do
        allow(@context).to receive(:feature_enabled?).with(:quizzes_next).and_return(false)
      end

      context "flag is off" do
        it "returns false" do
          flag_state Feature::STATE_OFF
          expect(NewQuizzesFeaturesHelper.disable_content_rewriting?(@context)).to be false
        end
      end

      context "flag is on" do
        it "returns false" do
          flag_state Feature::STATE_ON
          expect(NewQuizzesFeaturesHelper.disable_content_rewriting?(@context)).to be false
        end
      end
    end
  end

  describe "#new_quizzes_common_cartridge_enabled?" do
    def flag_state(value)
      Account.site_admin.set_feature_flag!(:new_quizzes_common_cartridge, value)
    end

    context "quizzes_next is true" do
      before do
        allow(@context).to receive(:feature_enabled?).with(:quizzes_next).and_return(true)
      end

      context "flag is off" do
        it "returns false" do
          flag_state Feature::STATE_OFF
          expect(NewQuizzesFeaturesHelper.new_quizzes_common_cartridge_enabled?(@context)).to be false
        end
      end

      context "flag is on" do
        it "returns true" do
          flag_state Feature::STATE_ON
          expect(NewQuizzesFeaturesHelper.new_quizzes_common_cartridge_enabled?(@context)).to be true
        end
      end
    end

    context "quizzes_next is false" do
      before do
        allow(@context).to receive(:feature_enabled?).with(:quizzes_next).and_return(false)
      end

      context "flag is off" do
        it "returns false" do
          flag_state Feature::STATE_OFF
          expect(NewQuizzesFeaturesHelper.new_quizzes_common_cartridge_enabled?(@context)).to be false
        end
      end

      context "flag is on" do
        it "returns false" do
          flag_state Feature::STATE_ON
          expect(NewQuizzesFeaturesHelper.new_quizzes_common_cartridge_enabled?(@context)).to be false
        end
      end
    end
  end

  describe "#common_cartridge_qti_new_quizzes_import_enabled?" do
    def flag_state(value)
      Account.site_admin.set_feature_flag!(:common_cartridge_qti_new_quizzes_import, value)
    end

    context "new_quizzes_migration_enabled is true" do
      before do
        allow(@context).to receive(:feature_enabled?).with(:quizzes_next).and_return(true)
        @context.root_account.enable_feature!(:new_quizzes_migration)
      end

      context "flag is off" do
        it "returns false" do
          flag_state Feature::STATE_OFF
          expect(NewQuizzesFeaturesHelper.common_cartridge_qti_new_quizzes_import_enabled?(@context)).to be false
        end
      end

      context "flag is on" do
        it "returns true" do
          flag_state Feature::STATE_ON
          expect(NewQuizzesFeaturesHelper.common_cartridge_qti_new_quizzes_import_enabled?(@context)).to be true
        end
      end
    end

    context "new_quizzes_migration_enabled is false" do
      before do
        allow(@context).to receive(:feature_enabled?).with(:quizzes_next).and_return(false)
        @context.root_account.disable_feature!(:new_quizzes_migration)
      end

      context "flag is off" do
        it "returns false" do
          flag_state Feature::STATE_OFF
          expect(NewQuizzesFeaturesHelper.common_cartridge_qti_new_quizzes_import_enabled?(@context)).to be false
        end
      end

      context "flag is on" do
        it "returns false" do
          flag_state Feature::STATE_ON
          expect(NewQuizzesFeaturesHelper.common_cartridge_qti_new_quizzes_import_enabled?(@context)).to be false
        end
      end
    end
  end
end
