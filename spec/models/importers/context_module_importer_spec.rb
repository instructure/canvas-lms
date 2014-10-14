#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '../../../import_helper')

describe "Importing modules" do

  SYSTEMS.each do |system|
    if import_data_exists? system, 'module'
      it "should import from #{system}" do
        data = get_import_data(system, 'module')
        context = get_import_context(system)
        data[:modules_to_import] = {}
        expect(Importers::ContextModuleImporter.import_from_migration(data, context)).to be_nil
        expect(context.context_modules.count).to eq 0

        data[:modules_to_import][data[:migration_id]] = true
        Importers::ContextModuleImporter.import_from_migration(data, context)
        Importers::ContextModuleImporter.import_from_migration(data, context)
        expect(context.context_modules.count).to eq 1

        mod = ContextModule.where(migration_id: data[:migration_id]).first
        expect(mod.content_tags.count).to eq data[:items].count{|m|m[:linked_resource_type]=='URL_TYPE'}
        expect(mod.name).to eq data[:title]
      end
    end
  end
  
  it "should link to url objects" do
    data = get_import_data('vista', 'module')
    context = get_import_context('vista')
    context.external_url_hash = {}

    topic = Importers::ContextModuleImporter.import_from_migration(data, context)
    expect(topic.content_tags.count).to eq 2
  end
  
  it "should link to objects on the second pass" do
    data = get_import_data('bb8', 'module')
    context = get_import_context('bb8')
    context.external_url_hash = {}


    topic = Importers::ContextModuleImporter.import_from_migration(data, context)
    expect(topic.content_tags.count).to eq 0

    ass = get_import_data('bb8', 'assignment')
    Importers::AssignmentImporter.import_from_migration(ass, context)
    expect(context.assignments.count).to eq 1
    
    topic = Importers::ContextModuleImporter.import_from_migration(data, context)
    expect(topic.content_tags.count).to eq 1
  end

  it "should link to translated external tool urls" do
    data = { :migration_id => "1", :title => "derp",
      :items => [{
        :migration_id => 'mig1',
        :type => "linked_resource",
        :linked_resource_title => "whatevs",
        :linked_resource_type => "contextexternaltool",
        :linked_resource_id => '2',
        :url => "http://exmpale.com/stuff"
      },
      {
        :migration_id => 'mig2',
        :type => "linked_resource",
        :linked_resource_title => "whatevs2",
        :linked_resource_type => "contextexternaltool",
        :linked_resource_id => '3',
        :url => "http://exmpale2.com/stuff?query=yay"
      }]
    }

    course_model
    tool1 = @course.context_external_tools.create!(:name => "somethin", :domain => "exmpale.com",
                                                  :shared_secret => 'fake', :consumer_key => 'fake')
    tool2 = @course.context_external_tools.create!(:name => "somethin2", :domain => "exmpale2.com",
                                                  :shared_secret => 'fake', :consumer_key => 'fake')
    migration = ContentMigration.new
    migration.add_external_tool_translation('2', tool1, {'heresacustomfields' => 'hooray and stuff'})
    migration.add_external_tool_translation('3', tool1, {'different' => 'field'})

    topic = Importers::ContextModuleImporter.import_from_migration(data, @course, migration)
    topic.reload

    expect(topic.content_tags.count).to eq 2
    tag1 = topic.content_tags.where(migration_id: 'mig1').first
    expect(tag1.url).to eq 'http://exmpale.com/stuff?custom_heresacustomfields=hooray+and+stuff'
    expect(tag1.content).to eq tool1

    tag2 = topic.content_tags.where(migration_id: 'mig2').first
    expect(tag2.url).to eq 'http://exmpale2.com/stuff?query=yay&custom_different=field'
    expect(tag2.content).to eq tool2
  end

  it "should not create a blank tag if the content is not found" do
    data = { :migration_id => "1", :title => "derp",
             :items => [{
                :migration_id => 'mig1',
                :type => "linked_resource",
                :linked_resource_title => "whatevs",
                :linked_resource_type => "externalurl",
                :url => "http://exmpale.com/stuff"
              },
              {
                :migration_id => 'mig2',
                :type => "linked_resource",
                :linked_resource_title => "whatevs",
                :linked_resource_type => "WikiPage",
                :linked_resource_id => '2'
              }],
             :completion_requirements => [{:type => "must_view", :item_migration_id => "mig1"}]
    }

    course_model
    migration = ContentMigration.new
    mod = Importers::ContextModuleImporter.import_from_migration(data, @course, migration)
    mod.reload

    expect(mod.content_tags.count).to eq 1
  end

  it "should select module items for import" do
    data = get_import_data('', 'module-item-select')
    context = get_import_context
    migration = @course.content_migrations.create!
    migration.migration_settings[:migration_ids_to_import] = {:copy => {:context_modules => {'i2ef97656ba4eb818e23343af83e5a1c2' => '1'}}}
    Importers::ContextModuleImporter.select_linked_module_items(data, migration)
    expect(migration.import_object?('assignments', 'i5081fa7128437fc599f6ca652214111e')).to be_truthy
    expect(migration.import_object?('assignments', 'i852f8d38d28428ad2b3530e4f9017cff')).to be_falsy
    expect(migration.import_object?('quizzes', 'i0f944b0a62b3f92d42260381c2c8906d')).to be_truthy
    expect(migration.import_object?('quizzes', 'ib9c6f62b6ca21d60b8d2e360725d75d3')).to be_falsy
    expect(migration.import_object?('attachments', 'idd42dfdb8d1cf5e58e6a09668b592f5e')).to be_truthy
    expect(migration.import_object?('attachments', 'i421ccf46e5e490246599efc9a7423f64')).to be_falsy
    expect(migration.import_object?('wiki_pages', 'i33dc99b0f1e2eaf393029aa0ff9b498d')).to be_truthy
    expect(migration.import_object?('wiki_pages', 'i11afbd372438c7e6cd37e341fcf2df58')).to be_falsy
    expect(migration.import_object?('discussion_topics', 'i33dc99b0f1e2eaf393029aa0ff9b498d')).to be_truthy
    expect(migration.import_object?('discussion_topics', 'i4d8d4467ae30e6fe5a7b1ef42fcbabff')).to be_falsy
    expect(migration.import_object?('context_external_tools', 'i33dc99b0f1e2eaf393029aa0ff9b498d')).to be_truthy
  end

end
