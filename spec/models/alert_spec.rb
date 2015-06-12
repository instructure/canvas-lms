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
      it "should accept mass assignment of criteria" do
        alert = Alert.new(:context => Account.default, :recipients => [:student])
        alert.criteria = [{:criterion_type => 'Interaction', :threshold => 1}]
        expect(alert.criteria.length).to eq 1
        expect(alert.criteria.first.criterion_type).to eq 'Interaction'
        expect(alert.criteria.first.threshold).to eq 1
        alert.save!
        original_criterion_id = alert.criteria.first.id

        alert.criteria = [{:criterion_type => 'Interaction', :threshold => 7, :id => alert.criteria.first.id},
                          {:criterion_type => 'UserNote', :threshold => 6}]
        expect(alert.criteria.length).to eq 2
        expect(alert.criteria.first.id).to eq original_criterion_id
        expect(alert.criteria.first.threshold).to eq 7
        expect(alert.criteria.last).to be_new_record

        alert.criteria = []
        alert.criteria be_empty

        expect(AlertCriterion.where(id: original_criterion_id).first).to be_nil
      end
    end

    context "validation" do
      it "should require a context" do
        alert = Alert.new(:recipients => [:student], :criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
        expect(alert.save).to be_falsey
      end

      it "should require recipients" do
        alert = Account.default.alerts.build(:criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
        expect(alert.save).to be_falsey
      end

      it "should require criteria" do
        alert = Account.default.alerts.build(:recipients => [:student])
        expect(alert.save).to be_falsey
      end
    end
  end

  context "#resolve_recipients" do
    it "resolves to a student based on recipients list" do
      alert = Alert.new(:context => Account.default, :recipients => [:student])
      recipients = alert.resolve_recipients(1, [2,3])
      expect(recipients).to eq [1]
    end

    it "resolves to teachers based on recipients list" do
      alert = Alert.new(:context => Account.default, :recipients => [:teachers])
      recipients = alert.resolve_recipients(1, [2,3])
      expect(recipients).to eq [2,3]
    end

    it "resolves to an admin based on recipients list" do
      admin = account_admin_user
      alert = Alert.new(:context => Account.default, :recipients => ['AccountAdmin'])
      recipients = alert.resolve_recipients(1, [2,3])
      expect(recipients).to eq [admin.id]
    end
  end
end
