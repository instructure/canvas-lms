require 'spec_helper'

module RuboCop::Canvas
  describe GitProxy do
    describe ".dirty?" do
      it "is true for any change list" do
        changes = %{
           M gems/rubocop-canvas/lib/rubocop_canvas.rb
           M gems/rubocop-canvas/spec/rubocop/canvas/comments_spec.rb
           M script/rlint
           ?? gems/rubocop-canvas/lib/rubocop_canvas/helpers/file_sieve.rb
           ?? gems/rubocop-canvas/lib/rubocop_canvas/helpers/git_proxy.rb
           ?? gems/rubocop-canvas/spec/rubocop/canvas/file_sieve_spec.rb
           ?? gems/rubocop-canvas/spec/rubocop/canvas/git_proxy_spec.rb
        }

        expect(described_class.dirty?(changes)).to be(true)
      end

      it "is false for an empty list" do
        expect(described_class.dirty?("")).to be(false)
      end

      it "doesnt count whitespace as changes" do
        expect(described_class.dirty?(" \n ")).to be(false)
      end
    end

    describe ".head_sha" do
      subject(:sha){ described_class.head_sha }

      it "is a string" do
        expect(sha).to be_a(String)
      end

      it "has no surrounding whitespace" do
        expect(sha.strip).to eq(sha)
      end

      it "is only one line" do
        expect(sha =~ /\n/).to be(nil)
      end
    end
  end
end
