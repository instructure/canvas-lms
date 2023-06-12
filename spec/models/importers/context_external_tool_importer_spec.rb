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

describe Importers::ContextExternalToolImporter do
  before :once do
    course_model
  end

  it "works for course-level tools" do
    migration = @course.content_migrations.create!
    tool = Importers::ContextExternalToolImporter.import_from_migration({ title: "tool", url: "http://example.com" }, @course, migration)
    expect(tool).not_to be_nil
    expect(tool.context).to eq @course
  end

  it 'does not create a new record if "persist" is falsey' do
    migration = @course.content_migrations.create!
    expect do
      Importers::ContextExternalToolImporter.import_from_migration({ title: "tool", url: "http://example.com" }, @course, migration, nil, false)
    end.not_to change { ContextExternalTool.count }
  end

  it "works for account-level tools" do
    migration = @course.account.content_migrations.create!
    tool = Importers::ContextExternalToolImporter.import_from_migration({ title: "tool", url: "http://example.com" }, @course.account, migration)
    expect(tool).not_to be_nil
    expect(tool.context).to eq @course.account
  end

  it "does not create a new tool with the same identity_hash as another tool" do
    tool = external_tool_model(context: @course)
    import_hash = tool.slice(*ContextExternalTool::IDENTITY_FIELDS)
    import_hash[:title] = import_hash.delete :name
    import_hash[:privacy_level] = import_hash.delete :workflow_state
    migration = @course.account.content_migrations.create!
    expect do
      Importers::ContextExternalToolImporter.import_from_migration(import_hash, @course, migration, nil, true)
    end.not_to change { ContextExternalTool.count }
  end

  it "updates an existing tool's identity_hash to 'duplicate' if it is changed to match another tool" do
    tool1 = external_tool_model(context: @course)
    tool2 = external_tool_model(context: @course, opts: { name: "t", migration_id: "hi" })
    import_hash = tool2.slice(*ContextExternalTool::IDENTITY_FIELDS)
    import_hash.delete :name
    import_hash[:title] = tool1.name
    import_hash[:privacy_level] = import_hash.delete :workflow_state
    import_hash[:migration_id] = "hi"
    migration = @course.account.content_migrations.create!
    expect do
      Importers::ContextExternalToolImporter.import_from_migration(import_hash, @course, migration, nil, true)
    end.not_to change { ContextExternalTool.count }
    expect(tool2.reload.identity_hash).to eq "duplicate"
  end

  context "when importing LTI 1.3 tool" do
    subject do
      Importers::ContextExternalToolImporter.import_from_migration(
        tool_hash,
        course.account,
        migration
      )
    end

    let(:course) { @course }
    let(:developer_key) { DeveloperKey.create!(account: course.account) }
    let(:migration) { course.content_migrations.create! }
    let(:settings) { { client_id: developer_key.global_id } }
    let(:tool_hash) do
      {
        title: "LTI 1.3 Tool",
        url: "http://www.example.com",
        lti_version: "1.3",
        settings:
      }
    end

    it "sets the developer key id" do
      expect(subject.developer_key).to eq developer_key
    end

    it "sets the lti_version" do
      expect(subject.lti_version).to eq "1.3"
    end

    context "when lti_version isn't present in hash" do
      before do
        tool_hash.delete :lti_version
      end

      context "but developer_key is present" do
        it "sets the lti_version" do
          expect(subject.lti_version).to eq "1.3"
        end
      end

      context "but use_1_3 is present in settings" do
        before do
          settings[:use_1_3] = true
        end

        it "sets the lti_version" do
          expect(subject.lti_version).to eq "1.3"
        end
      end

      context "without developer_key" do
        before do
          settings.delete :client_id
        end

        it "defaults lti_version to 1.1" do
          expect(subject.lti_version).to eq "1.1"
        end
      end
    end

    it "does not show LTI 1 warnings" do
      subject
      expect(migration.warnings).to be_empty
    end
  end

  context "placement configuration" do
    subject do
      Importers::ContextExternalToolImporter.import_from_migration(
        tool_hash,
        course.account,
        migration,
        tool
      )
    end

    let(:course) { @course }
    let(:migration) { course.content_migrations.create! }
    let(:tool) { external_tool_model(context: course) }
    let(:tool_hash) do
      {
        title: "test tool",
        settings: {
          oauth_compliant: true,
          course_navigation: {
            text: "Course Nav"
          }
        }
      }
    end

    before do
      allow(tool).to receive(:settings=).and_call_original
      allow(tool).to receive(:set_extension_setting).and_call_original
    end

    context "for placement tool has defined" do
      let(:placement) { :course_navigation }

      it "uses tool setter method" do
        subject
        expect(tool).to have_received(:settings=)
        expect(tool).to have_received(:set_extension_setting).with(:course_navigation, any_args)
      end
    end

    context "for placement tool does not have defined" do
      let(:placement) { :global_navigation }

      it "does not use tool setter method" do
        subject
        expect(tool).to have_received(:settings=)
      end
    end

    context "for settings attribute that is not a placement" do
      let(:placement) { :oauth_compliant }

      it "does not change" do
        subject
        expect(tool).to have_received(:settings=)
      end
    end
  end

  context "combining imported external tools" do
    before :once do
      @migration = ContentMigration.new(migration_type: "common_cartridge_importer")
    end

    it "does not combine if not common cartridge" do
      @migration.migration_type = "canvas_cartridge_importer"
      data = [
        { migration_id: "1", title: "tool", url: "http://example.com/page" },
        { migration_id: "2", title: "tool", domain: "example.com" },
      ]

      data.each do |hash|
        Importers::ContextExternalToolImporter.import_from_migration(hash, @course, @migration)
      end

      expect(@course.context_external_tools.map(&:migration_id).sort).to eq ["1", "2"]
    end

    it "combines an external tool with a url and one with a domain" do
      data = [
        { migration_id: "1", title: "tool", url: "http://example.com/page" },
        { migration_id: "2", title: "tool", domain: "example.com" },
        { migration_id: "3", title: "tool", url: "http://notexample.com" }
      ]
      data.each do |hash|
        Importers::ContextExternalToolImporter.import_from_migration(hash, @course, @migration)
      end

      expect(@course.context_external_tools.map(&:migration_id).sort).to eq ["1", "3"]
      tool = @course.context_external_tools.where(migration_id: "1").first
      expect(tool.domain).to eq "example.com"
      expect(tool.url).to be_blank
      expect(tool.name).to eq "example.com"
      expect(@migration.find_external_tool_translation("1")).to eq [tool.id, nil]
      expect(@migration.find_external_tool_translation("2")).to eq [tool.id, nil]
      expect(@migration.find_external_tool_translation("3")).to be_nil
    end

    it "combines two external tools with urls (if they're on the same domain)" do
      data = [
        { migration_id: "1", title: "tool", url: "http://example.com/page" },
        { migration_id: "2", title: "tool", url: "http://example.com/otherpage" },
        { migration_id: "3", title: "tool", url: "http://example.com", shared_secret: "notfake" }
      ]

      data.each do |hash|
        Importers::ContextExternalToolImporter.import_from_migration(hash, @course, @migration)
      end

      expect(@course.context_external_tools.map(&:migration_id).sort).to eq ["1", "3"]
      tool = @course.context_external_tools.where(migration_id: "1").first
      expect(tool.domain).to eq "example.com"
      expect(tool.url).to be_blank
      expect(tool.name).to eq "example.com"
      expect(@migration.find_external_tool_translation("1")).to eq [tool.id, nil]
      expect(@migration.find_external_tool_translation("2")).to eq [tool.id, nil]
      expect(@migration.find_external_tool_translation("3")).to be_nil
    end

    it "includes the custom fields in translation (if they're on the same domain)" do
      data = [
        { migration_id: "1", title: "tool", url: "http://example.com/page?query=present", custom_fields: { "ihasacustomfield" => "blah" } },
        { migration_id: "2", title: "tool", url: "http://example.com/otherpage", custom_fields: { "bloop" => "so do i" } },
        { migration_id: "3", title: "tool", url: "http://example.com", settings: { different_settings: "1" } }
      ]

      data.each do |hash|
        Importers::ContextExternalToolImporter.import_from_migration(hash, @course, @migration)
      end

      expect(@course.context_external_tools.map(&:migration_id).sort).to eq ["1", "3"]
      tool = @course.context_external_tools.where(migration_id: "1").first
      expect(tool.domain).to eq "example.com"
      expect(tool.url).to be_blank
      expect(tool.name).to eq "example.com"
      expect(@migration.find_external_tool_translation("1")).to eq [tool.id, { "ihasacustomfield" => "blah" }]
      expect(@migration.find_external_tool_translation("2")).to eq [tool.id, { "bloop" => "so do i" }]
      expect(@migration.find_external_tool_translation("3")).to be_nil
    end

    it "does not combine external tools with extremely long custom fields" do
      data = [
        { migration_id: "1", title: "tool", domain: "example.com" },
        { migration_id: "2", title: "tool", url: "http://example.com/otherpage" },
        { migration_id: "3", title: "tool", url: "http://example.com", custom_fields: { ("a" * 1000) => ("b" * 1000) } }
      ]

      data.each do |hash|
        Importers::ContextExternalToolImporter.import_from_migration(hash, @course, @migration)
      end

      expect(@course.context_external_tools.map(&:migration_id).sort).to eq ["1", "3"]
      tool = @course.context_external_tools.where(migration_id: "1").first
      expect(tool.domain).to eq "example.com"
      expect(tool.url).to be_blank
      expect(tool.name).to eq "example.com"
      expect(@migration.find_external_tool_translation("1")).to be_nil
      expect(@migration.find_external_tool_translation("2")).to eq [tool.id, nil]
      expect(@migration.find_external_tool_translation("3")).to be_nil
    end

    it "combines external tools with the same settings" do
      data = [
        { migration_id: "1", title: "tool", domain: "example.com", settings: { not_null: :same, vendor_extensions: { "oi" => "hoyt" } } },
        { migration_id: "2", title: "tool", url: "http://example.com/otherpage", settings: { not_null: :same, vendor_extensions: { "oi" => "heyhey" } } },
      ]

      data.each do |hash|
        Importers::ContextExternalToolImporter.import_from_migration(hash, @course, @migration)
      end

      expect(@course.context_external_tools.map(&:migration_id).sort).to eq ["1"]
      tool = @course.context_external_tools.where(migration_id: "1").first
      expect(tool.domain).to eq "example.com"
      expect(tool.url).to be_blank
      expect(tool.name).to eq "example.com"
      expect(@migration.find_external_tool_translation("1")).to be_nil
      expect(@migration.find_external_tool_translation("2")).to eq [tool.id, nil]
    end
  end

  context "searching for existing tools" do
    before :once do
      @tool1 = Account.default.context_external_tools.create!(name: "tool",
                                                              domain: "example.com",
                                                              shared_secret: "secret",
                                                              consumer_key: "test",
                                                              privacy_level: "name_only")
      @tool1.settings[:selection_width] = 100
      @tool1.save!
      @tool2 = Account.default.context_external_tools.create!(name: "tool",
                                                              url: "http://notexample.com/whatever",
                                                              shared_secret: "secret",
                                                              consumer_key: "test",
                                                              privacy_level: "name_only")
      @migration = @course.content_migrations.new(migration_type: "canvas_cartridge_importer")
      @data = [
        { migration_id: "1",
          title: "tool",
          url: "http://example.com/page",
          custom_fields: { "ihasacustomfield" => "blah" } },
        { migration_id: "2", title: "tool", domain: "example.com", selection_width: "100" },
        { migration_id: "3", title: "tool", url: "http://notexample.com" },
        { migration_id: "4", title: "tool", url: "http://notexample.com/whatever" } # should match @tool2 on exact url
      ]
    end

    it "does not search if setting not enabled" do
      @data.each do |hash|
        Importers::ContextExternalToolImporter.import_from_migration(hash, @course, @migration)
      end

      expect(@course.context_external_tools.map(&:migration_id).sort).to eq %w[1 2 3 4]
    end

    it "searches for existing tools if setting enabled" do
      @migration.migration_settings[:prefer_existing_tools] = true
      @data.each do |hash|
        Importers::ContextExternalToolImporter.import_from_migration(hash, @course, @migration)
      end

      expect(@course.context_external_tools.map(&:migration_id).sort).to eq ["3"]

      expect(@migration.find_external_tool_translation("1")).to eq [@tool1.id, { "ihasacustomfield" => "blah" }]
      expect(@migration.find_external_tool_translation("2")).to eq [@tool1.id, nil]
      expect(@migration.find_external_tool_translation("4")).to eq [@tool2.id, nil]
    end

    it "does not use an existing tool if the names don't match" do
      @migration.migration_settings[:prefer_existing_tools] = true
      @data.each do |hash|
        if hash[:migration_id] == "4"
          hash[:title] = "haha totally different tool"
        end
        Importers::ContextExternalToolImporter.import_from_migration(hash, @course, @migration)
      end

      expect(@course.context_external_tools.map(&:migration_id).sort).to eq ["3", "4"] # brings in tool 4 now
    end

    it "uses an existing tool even if the names don't match if we're doing regular cc import" do
      # because tool compaction changes the name
      @migration.migration_settings[:prefer_existing_tools] = true
      @migration.migration_type = "common_cartridge_importer"
      @data.each do |hash|
        if hash[:migration_id] == "4"
          hash[:title] = "haha totally different tool"
        end
        Importers::ContextExternalToolImporter.import_from_migration(hash, @course, @migration)
      end

      expect(@course.context_external_tools.map(&:migration_id).sort).to eq ["3"] # still compacts
    end
  end
end
