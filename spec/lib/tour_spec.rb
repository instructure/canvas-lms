require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe Tour do
  describe "tour" do
    let(:block) {
      Proc.new { true }
    }

    def assert_tour
      tour = Tour.tours[:fake]
      expect(tour[:name]).to eq :fake
      expect(tour[:version]).to eq 1
      expect(tour[:actions]).to eq ['controller#action']
      expect(tour[:block]).to eq block
    end

    it "should configure an tour" do
      Tour.tour :fake, 1, 'controller#action', &block
      assert_tour
    end

    it "should configure an tour with a hash" do
      Tour.tour({
        :name => :fake,
        :version => 1,
        :actions => 'controller#action'
      }, &block)
      assert_tour
    end
  end

  describe "tours_to_run" do

    class FakeUser
      def preferences
        {:dismissed_tours => {:dismissed => 1}}
      end
    end

    class FakeController
      def initialize
        @current_user = FakeUser.new
      end
      def self.before_filter(name); true; end
      def controller_name; 'controller'; end

      def action_name; 'action'; end

      def session
        {:dismissed_tours => {:dismissed => 1}}
      end

      def api_request?; false; end
      include Tour
    end

    before :each do
      @controller = FakeController.new
    end

    def tour_included?(name)
      tours = @controller.tours_to_run
      tours && tours.include?(name.to_s.classify)
    end

    it "should add tours to js_env" do
      Tour.tour(:fake, 1, 'controller#action') { true }
      expect(tour_included?(:fake)).to be_truthy
    end

    it "should not include an tour if the block returns false" do
      Tour.tour(:fake, 1, 'controller#action') { false }
      expect(tour_included?(:fake)).to be_falsey
    end

    it "should include an tour if no block is given" do
      Tour.tour :fake, 1, 'controller#action'
      expect(tour_included?(:fake)).to be_truthy
    end

    it "should not include an tour if user has dismissed it" do
      Tour.tour :dismissed, 1, 'controller#action'
      expect(tour_included?(:dismissed)).to be_falsey
    end

    it "should not exclude an tour if user has dismissed an old version of it" do
      Tour.tour :dismissed, 2, 'controller#action'
      expect(tour_included?(:dismissed)).to be_truthy
    end

    it "should not include an tour if user has dismissed it this session" do
      Tour.tour :dismissed, 1, 'controller#action'
      expect(tour_included?(:dismissed)).to be_falsey
    end

  end

end

