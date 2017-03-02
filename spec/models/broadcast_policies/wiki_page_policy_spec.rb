require File.expand_path('../../spec_helper', File.dirname(__FILE__))
require_dependency "broadcast_policies/wiki_page_policy"

module BroadcastPolicies
  describe WikiPagePolicy do

    let(:course) do
      mock("Course").tap do |c|
        c.stubs(:unpublished?).returns(false)
        c.stubs(:concluded?).returns(false)
      end
    end

    let(:wiki) do
      mock("Wiki").tap do |w|
        w.stubs(:context).returns(course)
      end
    end

    let(:wiki_page) do
      mock("WikiPage").tap do |w|
        w.stubs(:created_at).returns(1.hour.ago)
        w.stubs(:published?).returns(true)
        w.stubs(:wiki).returns(wiki)
        w.stubs(:just_created).returns(false)
      end
    end
    let(:policy) { WikiPagePolicy.new(wiki_page) }

    describe '#should_dispatch_updated_wiki_page?' do
      before do
        wiki_page.stubs(:wiki_page_changed).returns(true)
        wiki_page.stubs(:changed_state).with(:active).returns(false)
      end

      it 'is true when the changed_while_published? inputs are true' do
        expect(policy.should_dispatch_updated_wiki_page?).to be_truthy
      end

      it 'is true when the changed_state inputs are true' do
        wiki_page.stubs(:wiki_page_changed).returns(false)
        wiki_page.stubs(:changed_state).with(:active).returns(true)
        expect(policy.should_dispatch_updated_wiki_page?).to be_truthy
      end

      def wont_send_when
        yield
        expect(policy.should_dispatch_updated_wiki_page?).to be_falsey
      end

      specify { wont_send_when { wiki_page.stubs(:created_at).returns 30.seconds.ago } }
      specify { wont_send_when { wiki_page.stubs(:published?).returns false } }
      specify { wont_send_when { wiki_page.stubs(:wiki_page_changed).returns false } }
      specify { wont_send_when { course.stubs(:unpublished?).returns true } }
      specify { wont_send_when { course.stubs(:concluded?).returns true } }
    end
  end
end
