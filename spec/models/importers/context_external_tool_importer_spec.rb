require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Importers::ContextExternalToolImporter do
  it "should work for course-level tools" do
    course_model
    tool = Importers::ContextExternalToolImporter.import_from_migration({:title => 'tool', :url => 'http://example.com'}, @course)
    expect(tool).not_to be_nil
    expect(tool.context).to eq @course
  end

  it "should work for account-level tools" do
    course_model
    tool = Importers::ContextExternalToolImporter.import_from_migration({:title => 'tool', :url => 'http://example.com'}, @course.account)
    expect(tool).not_to be_nil
    expect(tool.context).to eq @course.account
  end

  context "combining imported external tools" do
    before :once do
      course_model
      @migration = ContentMigration.new(:migration_type => "common_cartridge_importer")
    end

    it "should not combine if not common cartridge" do
      @migration.migration_type = "canvas_cartridge_importer"
      data = [
          {:migration_id => '1', :title => 'tool', :url => 'http://example.com/page'},
          {:migration_id => '2', :title => 'tool', :domain => 'example.com'},
      ]

      data.each do |hash|
        Importers::ContextExternalToolImporter.import_from_migration(hash, @course, @migration)
      end

      expect(@course.context_external_tools.map(&:migration_id).sort).to eq ['1', '2']
    end

    it "should combine an external tool with a url and one with a domain" do
      data = [
        {:migration_id => '1', :title => 'tool', :url => 'http://example.com/page'},
        {:migration_id => '2', :title => 'tool', :domain => 'example.com'},
        {:migration_id => '3', :title => 'tool', :url => 'http://notexample.com'}
      ]
      data.each do |hash|
        Importers::ContextExternalToolImporter.import_from_migration(hash, @course, @migration)
      end

      expect(@course.context_external_tools.map(&:migration_id).sort).to eq ['1', '3']
      tool = @course.context_external_tools.where(migration_id: '1').first
      expect(tool.domain).to eq 'example.com'
      expect(tool.url).to be_blank
      expect(tool.name).to eq 'example.com'
      expect(@migration.find_external_tool_translation('1')).to eq [tool.id, nil]
      expect(@migration.find_external_tool_translation('2')).to eq [tool.id, nil]
      expect(@migration.find_external_tool_translation('3')).to be_nil
    end

    it "should combine two external tools with urls (if they're on the same domain)" do
      data = [
          {:migration_id => '1', :title => 'tool', :url => 'http://example.com/page'},
          {:migration_id => '2', :title => 'tool', :url => 'http://example.com/otherpage'},
          {:migration_id => '3', :title => 'tool', :url => 'http://example.com', :shared_secret => 'notfake'}
      ]

      data.each do |hash|
        Importers::ContextExternalToolImporter.import_from_migration(hash, @course, @migration)
      end

      expect(@course.context_external_tools.map(&:migration_id).sort).to eq ['1', '3']
      tool = @course.context_external_tools.where(migration_id: '1').first
      expect(tool.domain).to eq 'example.com'
      expect(tool.url).to be_blank
      expect(tool.name).to eq 'example.com'
      expect(@migration.find_external_tool_translation('1')).to eq [tool.id, nil]
      expect(@migration.find_external_tool_translation('2')).to eq [tool.id, nil]
      expect(@migration.find_external_tool_translation('3')).to be_nil
    end

    it "should include the custom fields in translation (if they're on the same domain)" do
      data = [
          {:migration_id => '1', :title => 'tool', :url => 'http://example.com/page?query=present', :custom_fields => {'ihasacustomfield' => 'blah'}},
          {:migration_id => '2', :title => 'tool', :url => 'http://example.com/otherpage', :custom_fields => {'bloop' => 'so do i'}},
          {:migration_id => '3', :title => 'tool', :url => 'http://example.com', :settings => {:different_settings => '1'}}
      ]

      data.each do |hash|
        Importers::ContextExternalToolImporter.import_from_migration(hash, @course, @migration)
      end

      expect(@course.context_external_tools.map(&:migration_id).sort).to eq ['1', '3']
      tool = @course.context_external_tools.where(migration_id: '1').first
      expect(tool.domain).to eq 'example.com'
      expect(tool.url).to be_blank
      expect(tool.name).to eq 'example.com'
      expect(@migration.find_external_tool_translation('1')).to eq [tool.id, {'ihasacustomfield' => 'blah'}]
      expect(@migration.find_external_tool_translation('2')).to eq [tool.id, {'bloop' => 'so do i'}]
      expect(@migration.find_external_tool_translation('3')).to be_nil
    end

    it "should not combine external tools with extremely long custom fields" do
      data = [
          {:migration_id => '1', :title => 'tool', :domain => 'example.com'},
          {:migration_id => '2', :title => 'tool', :url => 'http://example.com/otherpage'},
          {:migration_id => '3', :title => 'tool', :url => 'http://example.com', :custom_fields => {('a' * 1000) => ('b' * 1000)}}
      ]

      data.each do |hash|
        Importers::ContextExternalToolImporter.import_from_migration(hash, @course, @migration)
      end

      expect(@course.context_external_tools.map(&:migration_id).sort).to eq ['1', '3']
      tool = @course.context_external_tools.where(migration_id: '1').first
      expect(tool.domain).to eq 'example.com'
      expect(tool.url).to be_blank
      expect(tool.name).to eq 'example.com'
      expect(@migration.find_external_tool_translation('1')).to be_nil
      expect(@migration.find_external_tool_translation('2')).to eq [tool.id, nil]
      expect(@migration.find_external_tool_translation('3')).to be_nil
    end

    it "should combine external tools with the same settings" do
      data = [
          {:migration_id => '1', :title => 'tool', :domain => 'example.com', :settings => {:not_null => :same, :vendor_extensions => {'oi' => 'hoyt'}}},
          {:migration_id => '2', :title => 'tool', :url => 'http://example.com/otherpage', :settings => {:not_null => :same, :vendor_extensions => {'oi' => 'heyhey'}}},
      ]

      data.each do |hash|
        Importers::ContextExternalToolImporter.import_from_migration(hash, @course, @migration)
      end

      expect(@course.context_external_tools.map(&:migration_id).sort).to eq ['1']
      tool = @course.context_external_tools.where(migration_id: '1').first
      expect(tool.domain).to eq 'example.com'
      expect(tool.url).to be_blank
      expect(tool.name).to eq 'example.com'
      expect(@migration.find_external_tool_translation('1')).to be_nil
      expect(@migration.find_external_tool_translation('2')).to eq [tool.id, nil]
    end
  end

end
