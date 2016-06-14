require 'spec_helper'

describe Twitter::Connection do

  describe ".config=" do
    it "accepts any object with a call interface" do
      conf_class = Class.new do
        def call
          { 'monkey' => 'banana' }
        end
      end

      described_class.config =  conf_class.new
      expect(described_class.config['monkey']).to eq('banana')
    end

    it "rejects configs that are not callable" do
      expect { described_class.config = Object.new }.to(
        raise_error(RuntimeError) do |e|
          expect(e.message).to match(/must respond to/)
        end
      )
    end
  end

end
