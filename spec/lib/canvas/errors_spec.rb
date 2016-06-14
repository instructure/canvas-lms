require 'spec_helper'
module Canvas
  describe Errors do
    before(:each) do
      @old_registry = described_class.instance_variable_get(:@registry)
      described_class.clear_callback_registry!
    end

    after(:each) do
      described_class.instance_variable_set(:@registry, @old_registry)
    end

    let(:error){ stub("Some Error") }

    describe '.capture_exception' do
      it 'tags with the exception type' do
        exception = details = nil
        Canvas::Errors.register!(:test_thing) do |e, d|
          exception = e
          details = d
        end
        Canvas::Errors.capture_exception(:core_meltdown, error)
        expect(exception).to eq(error)
        expect(details).to eq({tags: {type: 'core_meltdown'}})
      end
    end

    it 'fires callbacks when it handles an exception' do
      called_with = nil
      Canvas::Errors.register!(:test_thing) do |exception|
        called_with = exception
      end
      Canvas::Errors.capture(error)
      expect(called_with).to eq(error)
    end

    it "passes through extra information if available wrapped in extra" do
      extra_info = nil
      Canvas::Errors.register!(:test_thing) do |_exception, details|
        extra_info = details
      end
      Canvas::Errors.capture(stub(), {detail1: 'blah'})
      expect(extra_info).to eq({extra: {detail1: 'blah'}})
    end

    it 'captures output from each callback according to their registry tag' do
      Canvas::Errors.register!(:test_thing) do
        "FOO-BAR"
      end
      outputs = Canvas::Errors.capture(stub())
      expect(outputs[:test_thing]).to eq('FOO-BAR')
    end
  end
end
