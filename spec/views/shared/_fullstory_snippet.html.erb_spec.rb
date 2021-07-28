# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "shared/_fullstory_snippet.html.erb" do
  before do
    controller.singleton_class.class_eval do

      protected
      def fullstory_app_key
        "fak"
      end
      helper_method :fullstory_app_key

    end

    @context = {}
    @current_user = User.new
    @domain_root_account = Account.default
    assign(:context, @context)
    assign(:current_user, @current_user)
    assign(:domain_root_account, @domain_root_account)
  end

  it "should render" do
    render partial: "shared/fullstory_snippet", locals: { }
    expect(response).not_to be_nil
  end

  it "includes the homeroom variable when set" do
    allow(@current_user).to receive(:global_id).and_return(1)
    allow(@current_user).to receive(:id).and_return(1)
    allow(@domain_root_account).to receive(:settings).and_return( { enable_fullstory: true} )
    render partial: "shared/fullstory_snippet", locals: { }
    expect(response.body).to include("feature_homeroom_course_bool")
  end
end

