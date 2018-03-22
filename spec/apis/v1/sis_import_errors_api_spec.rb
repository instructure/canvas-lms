#
# Copyright (C) 2018 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe SisImportsApiController, type: :request do
  before :once do
    @user = user_with_pseudonym :active_all => true
    @account = Account.default
    @account.allow_sis_import = true
    @account.save
    @account.account_users.create!(user: @user)
    @batch = @account.sis_batches.create
    3.times do |i|
      @batch.sis_batch_errors.create(root_account: @account,
                                     file: 'users.csv',
                                     message: "some error message #{i}",
                                     row: i)
    end
  end

  it 'should show errors for a sis_batch' do
    json = api_call(:get, "/api/v1/accounts/#{@account.id}/sis_imports/#{@batch.id}/errors",
                    {controller: 'sis_import_errors_api', action: 'index',
                     format: 'json', account_id: @account.id.to_s, id: @batch.id.to_s})
    expect(json["sis_import_errors"]).to eq [{"sis_import_id" => @batch.id, "file" => "users.csv",
                                              "message" => "some error message 2", "row" => 2},
                                             {"sis_import_id" => @batch.id, "file" => "users.csv",
                                              "message" => "some error message 1", "row" => 1},
                                             {"sis_import_id" => @batch.id, "file" => "users.csv",
                                              "message" => "some error message 0", "row" => 0}]
  end

  it 'should show errors for a root_account' do
    batch = @account.sis_batches.create
    2.times do |i|
      batch.sis_batch_errors.create(root_account: @account,
                                    file: 'courses.csv',
                                    message: "some error message #{i}",
                                    row: i)
    end
    json = api_call(:get, "/api/v1/accounts/#{@account.id}/sis_import_errors",
                    {controller: 'sis_import_errors_api', action: 'index',
                     format: 'json', account_id: @account.id.to_s})
    expect(json["sis_import_errors"]).to eq [{"sis_import_id" => batch.id, "file" => "courses.csv",
                                              "message" => "some error message 1", "row" => 1},
                                             {"sis_import_id" => batch.id, "file" => "courses.csv",
                                              "message" => "some error message 0", "row" => 0},
                                             {"sis_import_id" => @batch.id, "file" => "users.csv",
                                              "message" => "some error message 2", "row" => 2},
                                             {"sis_import_id" => @batch.id, "file" => "users.csv",
                                              "message" => "some error message 1", "row" => 1},
                                             {"sis_import_id" => @batch.id, "file" => "users.csv",
                                              "message" => "some error message 0", "row" => 0}]
  end
end
