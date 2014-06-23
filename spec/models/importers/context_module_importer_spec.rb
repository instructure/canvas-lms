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
    tag1.url.should == 'http://exmpale.com/stuff?heresacustomfields=hooray+and+stuff'
    tag1.content.should == tool1

    tag2 = topic.content_tags.find_by_migration_id('mig2')
    tag2.url.should == 'http://exmpale2.com/stuff?query=yay&different=field'
    tag2.content.should == tool2
  end

end
