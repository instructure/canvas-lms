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
        Importers::ContextModuleImporter.import_from_migration(data, context).should be_nil
        context.context_modules.count.should == 0

        data[:modules_to_import][data[:migration_id]] = true
        Importers::ContextModuleImporter.import_from_migration(data, context)
        Importers::ContextModuleImporter.import_from_migration(data, context)
        context.context_modules.count.should == 1

        mod = ContextModule.find_by_migration_id(data[:migration_id])
        mod.content_tags.count.should == data[:items].count{|m|m[:linked_resource_type]=='URL_TYPE'}
        mod.name.should == data[:title]
      end
    end
  end
  
  it "should link to url objects" do
    data = get_import_data('vista', 'module')
    context = get_import_context('vista')
    context.external_url_hash = {}

    topic = Importers::ContextModuleImporter.import_from_migration(data, context)
    topic.content_tags.count.should == 2
  end
  
  it "should link to objects on the second pass" do
    data = get_import_data('bb8', 'module')
    context = get_import_context('bb8')
    context.external_url_hash = {}


    topic = Importers::ContextModuleImporter.import_from_migration(data, context)
    topic.content_tags.count.should == 0

    ass = get_import_data('bb8', 'assignment')
    Importers::AssignmentImporter.import_from_migration(ass, context)
    context.assignments.count.should == 1
    
    topic = Importers::ContextModuleImporter.import_from_migration(data, context)
    topic.content_tags.count.should == 1
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

    topic.content_tags.count.should == 2
    tag1 = topic.content_tags.find_by_migration_id('mig1')
    tag1.url.should == 'http://exmpale.com/stuff?custom_heresacustomfields=hooray+and+stuff'
    tag1.content.should == tool1

    tag2 = topic.content_tags.find_by_migration_id('mig2')
    tag2.url.should == 'http://exmpale2.com/stuff?query=yay&custom_different=field'
    tag2.content.should == tool2
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

    mod.content_tags.count.should == 1
  end

  it "should select module items for import" do
    data = get_import_data('', 'module-item-select')
    context = get_import_context
    migration = @course.content_migrations.create!
    migration.migration_settings[:migration_ids_to_import] = {:copy => {:context_modules => {'i2ef97656ba4eb818e23343af83e5a1c2' => '1'}}}
    Importers::ContextModuleImporter.select_linked_module_items(data, migration)
    migration.import_object?('assignments', 'i5081fa7128437fc599f6ca652214111e').should be_truthy
    migration.import_object?('assignments', 'i852f8d38d28428ad2b3530e4f9017cff').should be_falsy
    migration.import_object?('quizzes', 'i0f944b0a62b3f92d42260381c2c8906d').should be_truthy
    migration.import_object?('quizzes', 'ib9c6f62b6ca21d60b8d2e360725d75d3').should be_falsy
    migration.import_object?('attachments', 'idd42dfdb8d1cf5e58e6a09668b592f5e').should be_truthy
    migration.import_object?('attachments', 'i421ccf46e5e490246599efc9a7423f64').should be_falsy
    migration.import_object?('wiki_pages', 'i33dc99b0f1e2eaf393029aa0ff9b498d').should be_truthy
    migration.import_object?('wiki_pages', 'i11afbd372438c7e6cd37e341fcf2df58').should be_falsy
    migration.import_object?('discussion_topics', 'i33dc99b0f1e2eaf393029aa0ff9b498d').should be_truthy
    migration.import_object?('discussion_topics', 'i4d8d4467ae30e6fe5a7b1ef42fcbabff').should be_falsy
    migration.import_object?('context_external_tools', 'i33dc99b0f1e2eaf393029aa0ff9b498d').should be_truthy
  end

end
