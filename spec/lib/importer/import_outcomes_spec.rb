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

describe "Importing Learning Outcomes" do
  it "should import" do
    context = course_model
    migration = ContentMigration.create!(:context => context)
    migration.migration_ids_to_import = {:copy=>{}}
    data = get_import_data [], 'outcomes'
    data = {'learning_outcomes'=>data}

    LearningOutcome.process_migration(data, migration)
    LearningOutcome.process_migration(data, migration)

    LearningOutcome.count.should == 2
    lo1 = LearningOutcome.find_by_migration_id("bdf6dc13-5d8f-43a8-b426-03380c9b6781")
    lo1.description.should == "Outcome 1: Read stuff"
    lo2 = LearningOutcome.find_by_migration_id("fa67b467-37c7-4fb9-aef4-21a33a06d0be")
    lo2.description.should == "Outcome 2: follow directions"

    log = context.root_outcome_group
    log.child_outcome_links.detect{ |link| link.content == lo1 }.should_not be_nil
    log.child_outcome_links.detect{ |link| link.content == lo2 }.should_not be_nil
  end
end
