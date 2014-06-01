#
# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe Alert do
  before do
    @mock_notification = Notification.new
    Notification.stubs(:by_name).returns(@mock_notification)
  end

  context "Alerts" do
    context "mass assignment" do
      it "should translate string-symbols to symbols when assigning to recipients" do
        alert = Alert.new
        alert.recipients = [':student', :teachers, 'AccountAdmin']
        alert.recipients.should == [:student, :teachers, 'AccountAdmin']
      end

      it "should accept mass assignment of criteria" do
        alert = Alert.new(:context => Account.default, :recipients => [:student])
        alert.criteria = [{:criterion_type => 'Interaction', :threshold => 1}]
        alert.criteria.length.should == 1
        alert.criteria.first.criterion_type.should == 'Interaction'
        alert.criteria.first.threshold.should == 1
        alert.save!
        original_criterion_id = alert.criteria.first.id

        alert.criteria = [{:criterion_type => 'Interaction', :threshold => 7, :id => alert.criteria.first.id},
                          {:criterion_type => 'UserNote', :threshold => 6}]
        alert.criteria.length.should == 2
        alert.criteria.first.id.should == original_criterion_id
        alert.criteria.first.threshold.should == 7
        alert.criteria.last.should be_new_record

        alert.criteria = []
        alert.criteria be_empty

        AlertCriterion.find_by_id(original_criterion_id).should be_nil
      end
    end

    context "validation" do
      it "should require a context" do
        alert = Alert.new(:recipients => [:student], :criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
        alert.save.should be_false
      end

      it "should require recipients" do
        alert = Account.default.alerts.build(:criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
        alert.save.should be_false
      end

      it "should require criteria" do
        alert = Account.default.alerts.build(:recipients => [:student])
        alert.save.should be_false
      end
    end
  end
end
