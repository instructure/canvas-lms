# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

require "delayed/testing"

describe BrandConfigReconciler do
  before :once do
    @parent_account = Account.default
    @parent_account.brand_config = @parent_config = BrandConfig.for(variables: { "ic-brand-primary" => "red" })
    @parent_config.save!
    @parent_account.save!
    @parent_shared_config = @parent_account.shared_brand_configs.create!(
      name: "parent theme",
      brand_config_md5: @parent_config.md5
    )

    @child_account = Account.create!(parent_account: @parent_account, name: "child")
    @child_account.brand_config = @child_config = BrandConfig.for(variables: { "ic-brand-global-nav-bgd" => "white" }, parent_md5: @parent_config.md5)
    @child_config.save!
    @child_account.save!
    @child_shared_config = @child_account.shared_brand_configs.create!(
      name: "child theme",
      brand_config_md5: @child_config.md5
    )

    @grand_child_account = Account.create!(parent_account: @child_account, name: "grand_child")
    @grand_child_account.brand_config = @grand_child_config = BrandConfig.for(variables: { "ic-brand-global-nav-avatar-border" => "blue" }, parent_md5: @child_config.md5)
    @grand_child_config.save!
    @grand_child_account.save!
    @grand_child_shared_config = @grand_child_account.shared_brand_configs.create!(
      name: "grandchild theme",
      brand_config_md5: @grand_child_config.md5
    )
  end

  describe ".process" do
    it "enqueues jobs for each root account" do
      allow(Shard.current).to receive(:default?).and_return(false)
      expect(BrandConfigReconciler).to receive(:delay_if_production).at_least(:once).and_return(BrandConfigReconciler)
      expect(BrandConfigReconciler).to receive(:process_account_async).at_least(:once)
      BrandConfigReconciler.process
    end
  end

  describe ".process_account" do
    it "returns results hash" do
      allow_any_instance_of(BrandConfig).to receive(:save_all_files!)

      result = BrandConfigReconciler.process_account(@parent_account)

      expect(result).to include(:issues_found, :issues_fixed, :errors)
    end

    context "with dry_run: true" do
      before do
        allow_any_instance_of(BrandConfig).to receive(:save_all_files!)
      end

      it "detects issues without fixing them" do
        new_parent_config = BrandConfig.for(variables: { "ic-brand-primary" => "blue" })
        new_parent_config.save!
        @parent_account.update!(brand_config_md5: new_parent_config.md5)

        result = BrandConfigReconciler.process_account(@parent_account, dry_run: true)

        expect(result[:issues_found]).to be > 0
        expect(result[:issues_fixed]).to eq(0)
        expect(result[:issues]).to be_an(Array)
        expect(result[:issues]).not_to be_empty
        expect(result[:issues].first).to include(:type, :account)

        # Verify the config was NOT updated
        @child_account.reload
        expect(@child_account.brand_config.local_parent_md5).to eq(@parent_config.md5)
      end

      it "does not return issues array in normal mode" do
        result = BrandConfigReconciler.process_account(@parent_account, dry_run: false)

        expect(result).not_to include(:issues)
      end
    end
  end

  describe "#run" do
    before do
      allow_any_instance_of(BrandConfig).to receive(:save_all_files!)
    end

    context "when no issues exist" do
      it "completes without making changes" do
        result = BrandConfigReconciler.process_account(@parent_account)

        expect(result[:issues_found]).to eq(0)
        expect(result[:issues_fixed]).to eq(0)
      end
    end

    context "with stale parent reference" do
      it "detects when account brand_config.parent_md5 differs from expected" do
        # Update parent config but don't regenerate children
        new_parent_config = BrandConfig.for(variables: { "ic-brand-primary" => "blue" })
        new_parent_config.save!
        @parent_account.update!(brand_config_md5: new_parent_config.md5)

        # Child still points to old parent config
        expect(@child_config.local_parent_md5).to eq(@parent_config.md5)
        expect(@child_config.local_parent_md5).not_to eq(new_parent_config.md5)

        result = BrandConfigReconciler.process_account(@parent_account)

        expect(result[:issues_found]).to be > 0
      end

      it "fixes stale parent reference by regenerating config" do
        # Update parent config but don't regenerate children
        new_parent_config = BrandConfig.for(variables: { "ic-brand-primary" => "blue" })
        new_parent_config.save!
        @parent_account.update!(brand_config_md5: new_parent_config.md5)

        BrandConfigReconciler.process_account(@parent_account)

        @child_account.reload
        expect(@child_account.brand_config.local_parent_md5).to eq(new_parent_config.md5)
      end

      it "processes accounts in hierarchy order (parents before children)" do
        # Update parent config but don't regenerate children
        new_parent_config = BrandConfig.for(variables: { "ic-brand-primary" => "blue" })
        new_parent_config.save!
        @parent_account.update!(brand_config_md5: new_parent_config.md5)

        BrandConfigReconciler.process_account(@parent_account)

        # Both child and grandchild should be fixed, with grandchild pointing to new child config
        @child_account.reload
        @grand_child_account.reload

        expect(@child_account.brand_config.local_parent_md5).to eq(new_parent_config.md5)
        expect(@grand_child_account.brand_config.local_parent_md5).to eq(@child_account.brand_config.md5)
      end
    end

    context "with orphaned parent reference" do
      it "detects and fixes orphaned parent reference" do
        # Delete the parent config (simulating cleanup after failed regeneration)
        orphaned_md5 = @child_config.local_parent_md5
        @parent_account.update!(brand_config_md5: nil)
        # Delete shared_brand_configs first to avoid FK violation
        SharedBrandConfig.where(brand_config_md5: orphaned_md5).delete_all
        BrandConfig.where(md5: orphaned_md5).delete_all

        result = BrandConfigReconciler.process_account(@parent_account)

        expect(result[:issues_found]).to be > 0

        @child_account.reload
        # Child should now have no parent (since parent account has no config)
        expect(@child_account.brand_config.parent_md5).to be_nil
      end
    end

    context "with stale SharedBrandConfig" do
      it "detects and fixes SharedBrandConfig with stale parent" do
        # Update parent config but don't regenerate
        new_parent_config = BrandConfig.for(variables: { "ic-brand-primary" => "blue" })
        new_parent_config.save!
        @parent_account.update!(brand_config_md5: new_parent_config.md5)

        # The child shared config still points to old parent
        expect(@child_shared_config.brand_config.local_parent_md5).to eq(@parent_config.md5)

        result = BrandConfigReconciler.process_account(@parent_account)

        expect(result[:issues_found]).to be > 0

        @child_shared_config.reload
        expect(@child_shared_config.brand_config.local_parent_md5).to eq(new_parent_config.md5)
      end
    end

    context "when reconciliation fails" do
      it "captures error and continues processing other accounts" do
        # Update parent config to create stale references
        new_parent_config = BrandConfig.for(variables: { "ic-brand-primary" => "blue" })
        new_parent_config.save!
        @parent_account.update!(brand_config_md5: new_parent_config.md5)

        # Simulate failure for child account
        allow_any_instance_of(BrandConfig).to receive(:sync_to_s3_and_save_to_account!) do |bc, _progress, account|
          raise "S3 timeout" if account.id == @child_account.id

          # Normal behavior for other accounts
          old_md5 = account.brand_config_md5
          account.brand_config_md5 = bc.md5
          account.save!
          BrandConfig.destroy_if_unused(old_md5)
        end

        expect(Canvas::Errors).to receive(:capture_exception).at_least(:once)

        result = BrandConfigReconciler.process_account(@parent_account)

        expect(result[:errors]).to be > 0
      end
    end

    context "idempotency" do
      it "produces same result when run multiple times with no issues" do
        result1 = BrandConfigReconciler.process_account(@parent_account)
        result2 = BrandConfigReconciler.process_account(@parent_account)

        expect(result1).to eq(result2)
        expect(result1[:issues_found]).to eq(0)
      end

      it "finds no issues on second run after fixing" do
        # Create stale reference
        new_parent_config = BrandConfig.for(variables: { "ic-brand-primary" => "blue" })
        new_parent_config.save!
        @parent_account.update!(brand_config_md5: new_parent_config.md5)

        result1 = BrandConfigReconciler.process_account(@parent_account)
        expect(result1[:issues_found]).to be > 0

        result2 = BrandConfigReconciler.process_account(@parent_account)
        expect(result2[:issues_found]).to eq(0)
      end

      it "does not create duplicate BrandConfigs" do
        new_parent_config = BrandConfig.for(variables: { "ic-brand-primary" => "blue" })
        new_parent_config.save!
        @parent_account.update!(brand_config_md5: new_parent_config.md5)

        BrandConfigReconciler.process_account(@parent_account)
        count_after_first = BrandConfig.count

        BrandConfigReconciler.process_account(@parent_account)
        count_after_second = BrandConfig.count

        # Second run should not create any new configs
        expect(count_after_second).to eq(count_after_first)
      end
    end
  end
end
