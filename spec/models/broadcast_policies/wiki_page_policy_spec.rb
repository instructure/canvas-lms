# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module BroadcastPolicies
  describe WikiPagePolicy do
    let(:course) do
      double("Course").tap do |c|
        allow(c).to receive_messages(unpublished?: false, concluded?: false)
      end
    end

    let(:wiki) do
      double("Wiki").tap do |w|
        allow(w).to receive(:context).and_return(course)
      end
    end

    let(:wiki_page) do
      double("WikiPage").tap do |w|
        allow(w).to receive_messages(created_at: 1.hour.ago,
                                     published?: true,
                                     wiki:,
                                     context: course,
                                     just_created: false)
      end
    end
    let(:policy) { WikiPagePolicy.new(wiki_page) }

    describe "#should_dispatch_updated_wiki_page?" do
      before do
        allow(wiki_page).to receive(:wiki_page_changed).and_return(true)
        allow(wiki_page).to receive(:changed_state).with(:active).and_return(false)
      end

      it "is true when the changed_while_published? inputs are true" do
        expect(policy.should_dispatch_updated_wiki_page?).to be_truthy
      end

      it "is true when the changed_state inputs are true" do
        allow(wiki_page).to receive(:wiki_page_changed).and_return(false)
        allow(wiki_page).to receive(:changed_state).with(:active).and_return(true)
        expect(policy.should_dispatch_updated_wiki_page?).to be_truthy
      end

      def wont_send_when
        yield
        expect(policy.should_dispatch_updated_wiki_page?).to be_falsey
      end

      specify { wont_send_when { allow(wiki_page).to receive(:created_at).and_return 30.seconds.ago } }
      specify { wont_send_when { allow(wiki_page).to receive(:published?).and_return false } }
      specify { wont_send_when { allow(wiki_page).to receive(:wiki_page_changed).and_return false } }
      specify { wont_send_when { allow(course).to receive(:unpublished?).and_return true } }
      specify { wont_send_when { allow(course).to receive(:concluded?).and_return true } }
    end
  end
end
