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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe SisBatchRollBackData do
  before :once do
    @account = account_model
    @batch = @account.sis_batches.create!
  end

  it 'should create successfully' do
    c1 = Course.create!
    c2 = Course.create!
    d1 = SisBatchRollBackData.build_data(sis_batch: @batch,
                                         context: c1)
    d2 = SisBatchRollBackData.build_data(sis_batch: @batch,
                                         context: c2)
    SisBatchRollBackData.bulk_insert_roll_back_data([d1, d2])
    expect(@batch.roll_back_data.count).to eq 2
  end

  it 'should have each context respond to updated_at' do
    SisBatchRollBackData::RESTORE_ORDER.each do |type|
      expect(type.constantize.column_names.include?('updated_at')).to eq true
    end
  end
end
