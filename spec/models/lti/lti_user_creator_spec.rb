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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Lti::LtiUserCreator do
  describe '#convert' do
    let(:tool) do
      ContextExternalTool.new.tap do |tool|
        tool.stubs(:opaque_identifier_for).returns('this is opaque')
      end
    end

    it 'converts a canvas user to an lti user' do
      canvas_user = user(name: 'Shorty McLongishname')
      canvas_user.email = 'user@email.com'

      root_account = Account.create!
      sub_account = Account.create!
      sub_account.root_account = root_account
      sub_account.save!
      pseudonym = pseudonym(canvas_user, account: sub_account, username: 'login_id')

      pseudonym.sis_user_id = 'sis id!'
      pseudonym.save!

      Time.zone.tzinfo.stubs(:name).returns('my/zone')

      user_factory = Lti::LtiUserCreator.new(canvas_user, root_account, tool)
      lti_user = user_factory.convert

      lti_user.class.should == LtiOutbound::LTIUser

      lti_user.email.should == 'user@email.com'
      lti_user.first_name.should == 'Shorty'
      lti_user.last_name.should == 'McLongishname'
      lti_user.name.should == 'Shorty McLongishname'
      lti_user.sis_source_id.should == 'sis id!'
      lti_user.opaque_identifier.should == 'this is opaque'

      lti_user.avatar_url.should include 'https://secure.gravatar.com/avatar/'
      lti_user.login_id.should == 'login_id'
      lti_user.id.should == canvas_user.id
      lti_user.timezone.should == 'my/zone'
    end

    context 'the user does not have a pseudonym' do
      let(:user_creator) { Lti::LtiUserCreator.new(user, nil, tool) }

      it 'does not have a login_id' do
        lti_user = user_creator.convert

        lti_user.login_id.should == nil
      end

      it 'does not have a sis_user_id' do
        lti_user = user_creator.convert

        lti_user.sis_source_id.should == nil
      end
    end
  end
end