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

RSpec.shared_examples "outcome import context examples" do
  describe 'relationships' do
    it { is_expected.to have_many(:outcome_imports).dependent(:destroy).inverse_of(:context) }
    it { is_expected.to belong_to(:latest_outcome_import).class_name('OutcomeImport') }
  end

  it "should not raise error when setting latest outcome import" do
    a1 = described_class.create!
    oi = OutcomeImport.create!(context: a1)
    expect { a1.update!(latest_outcome_import: oi) }.not_to raise_error
  end

  it "should raise error on invalid latest outcome import" do
    a1 = described_class.create!
    oi = OutcomeImport.create!(context: described_class.create!)
    expect { a1.update!(latest_outcome_import: oi) }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
