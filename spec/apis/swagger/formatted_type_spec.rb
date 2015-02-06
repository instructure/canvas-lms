require File.expand_path(File.dirname(__FILE__) + '/swagger_helper')
require 'formatted_type'

describe FormattedType do
  let(:ft) { FormattedType.new(example) }
  subject{ ft }

  context "integer" do
    let(:example) { 1 }

    describe '#integer?' do
      subject { super().integer? }
      it { is_expected.to be_truthy }
    end

    describe '#float?' do
      subject { super().float? }
      it { is_expected.not_to be_truthy }
    end

    describe '#type_and_format' do
      subject { super().type_and_format }
      it { is_expected.to eq ["integer", "int64"] }
    end

    describe '#to_hash' do
      subject { super().to_hash }
      it { is_expected.to eq({"type" => "integer", "format" => "int64"}) }
    end
  end

  context "integer from string" do
    let(:example) { "1" }

    describe '#integer?' do
      subject { super().integer? }
      it { is_expected.to be_truthy }
    end

    describe '#float?' do
      subject { super().float? }
      it { is_expected.not_to be_truthy }
    end

    describe '#type_and_format' do
      subject { super().type_and_format }
      it { is_expected.to eq ["integer", "int64"] }
    end

    describe '#to_hash' do
      subject { super().to_hash }
      it { is_expected.to eq({"type" => "integer", "format" => "int64"}) }
    end
  end

  context "float" do
    let(:example) { 1.1 }

    describe '#integer?' do
      subject { super().integer? }
      it { is_expected.not_to be_truthy }
    end

    describe '#float?' do
      subject { super().float? }
      it { is_expected.to be_truthy }
    end

    describe '#type_and_format' do
      subject { super().type_and_format }
      it { is_expected.to eq ["number", "double"] }
    end

    describe '#to_hash' do
      subject { super().to_hash }
      it { is_expected.to eq({"type" => "number", "format" => "double"}) }
    end
  end

  context "float from string" do
    let(:example) { "1.1" }

    describe '#integer?' do
      subject { super().integer? }
      it { is_expected.not_to be_truthy }
    end

    describe '#float?' do
      subject { super().float? }
      it { is_expected.to be_truthy }
    end

    describe '#type_and_format' do
      subject { super().type_and_format }
      it { is_expected.to eq ["number", "double"] }
    end

    describe '#to_hash' do
      subject { super().to_hash }
      it { is_expected.to eq({"type" => "number", "format" => "double"}) }
    end
  end

  context "string" do
    let(:example) { "my name" }

    describe '#integer?' do
      subject { super().integer? }
      it { is_expected.not_to be_truthy }
    end

    describe '#float?' do
      subject { super().float? }
      it { is_expected.not_to be_truthy }
    end

    describe '#string?' do
      subject { super().string? }
      it { is_expected.to be_truthy }
    end

    describe '#type_and_format' do
      subject { super().type_and_format }
      it { is_expected.to eq ["string", nil] }
    end

    describe '#to_hash' do
      subject { super().to_hash }
      it { is_expected.to eq({"type" => "string"}) }
    end
  end

  context "boolean" do
    let(:example) { true }

    describe '#integer?' do
      subject { super().integer? }
      it { is_expected.not_to be_truthy }
    end

    describe '#float?' do
      subject { super().float? }
      it { is_expected.not_to be_truthy }
    end

    describe '#string?' do
      subject { super().string? }
      it { is_expected.not_to be_truthy }
    end

    describe '#boolean?' do
      subject { super().boolean? }
      it { is_expected.to be_truthy }
    end

    describe '#type_and_format' do
      subject { super().type_and_format }
      it { is_expected.to eq ["boolean", nil] }
    end

    describe '#to_hash' do
      subject { super().to_hash }
      it { is_expected.to eq({"type" => "boolean"}) }
    end
  end

  context "date" do
    let(:example) { "2012-01-01" }

    describe '#integer?' do
      subject { super().integer? }
      it { is_expected.not_to be_truthy }
    end

    describe '#float?' do
      subject { super().float? }
      it { is_expected.not_to be_truthy }
    end

    describe '#string?' do
      subject { super().string? }
      it { is_expected.to be_truthy }
    end

    describe '#date?' do
      subject { super().date? }
      it { is_expected.to be_truthy }
    end

    describe '#type_and_format' do
      subject { super().type_and_format }
      it { is_expected.to eq ["string", "date"] }
    end

    describe '#to_hash' do
      subject { super().to_hash }
      it { is_expected.to eq({"type" => "string", "format" => "date"}) }
    end
  end

  context "datetime" do
    let(:example) { "2012-01-01T12:00:00Z" }

    describe '#integer?' do
      subject { super().integer? }
      it { is_expected.not_to be_truthy }
    end

    describe '#float?' do
      subject { super().float? }
      it { is_expected.not_to be_truthy }
    end

    describe '#string?' do
      subject { super().string? }
      it { is_expected.to be_truthy }
    end

    describe '#date?' do
      subject { super().date? }
      it { is_expected.not_to be_truthy }
    end

    describe '#datetime?' do
      subject { super().datetime? }
      it { is_expected.to be_truthy }
    end

    describe '#type_and_format' do
      subject { super().type_and_format }
      it { is_expected.to eq ["string", "date-time"] }
    end

    describe '#to_hash' do
      subject { super().to_hash }
      it { is_expected.to eq({"type" => "string", "format" => "date-time"}) }
    end
  end

end