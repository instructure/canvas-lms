require File.expand_path(File.dirname(__FILE__) + '/swagger_helper')
require 'formatted_type'

describe FormattedType do
  let(:ft) { FormattedType.new(example) }
  subject{ ft }

  context "integer" do
    let(:example) { 1 }
    its(:integer?) { should be_true }
    its(:float?) { should_not be_true }
    its(:type_and_format) { should == ["integer", "int64"] }
    its(:to_hash) { should == {"type" => "integer", "format" => "int64"} }
  end

  context "integer from string" do
    let(:example) { "1" }
    its(:integer?) { should be_true }
    its(:float?) { should_not be_true }
    its(:type_and_format) { should == ["integer", "int64"] }
    its(:to_hash) { should == {"type" => "integer", "format" => "int64"} }
  end

  context "float" do
    let(:example) { 1.1 }
    its(:integer?) { should_not be_true }
    its(:float?) { should be_true }
    its(:type_and_format) { should == ["number", "double"] }
    its(:to_hash) { should == {"type" => "number", "format" => "double"} }
  end

  context "float from string" do
    let(:example) { "1.1" }
    its(:integer?) { should_not be_true }
    its(:float?) { should be_true }
    its(:type_and_format) { should == ["number", "double"] }
    its(:to_hash) { should == {"type" => "number", "format" => "double"} }
  end

  context "string" do
    let(:example) { "my name" }
    its(:integer?) { should_not be_true }
    its(:float?) { should_not be_true }
    its(:string?) { should be_true }
    its(:type_and_format) { should == ["string", nil] }
    its(:to_hash) { should == {"type" => "string"} }
  end

  context "boolean" do
    let(:example) { true }
    its(:integer?) { should_not be_true }
    its(:float?) { should_not be_true }
    its(:string?) { should_not be_true }
    its(:boolean?) { should be_true }
    its(:type_and_format) { should == ["boolean", nil] }
    its(:to_hash) { should == {"type" => "boolean"} }
  end

  context "date" do
    let(:example) { "2012-01-01" }
    its(:integer?) { should_not be_true }
    its(:float?) { should_not be_true }
    its(:string?) { should be_true }
    its(:date?) { should be_true }
    its(:type_and_format) { should == ["string", "date"] }
    its(:to_hash) { should == {"type" => "string", "format" => "date"} }
  end

  context "datetime" do
    let(:example) { "2012-01-01T12:00:00Z" }
    its(:integer?) { should_not be_true }
    its(:float?) { should_not be_true }
    its(:string?) { should be_true }
    its(:date?) { should_not be_true }
    its(:datetime?) { should be_true }
    its(:type_and_format) { should == ["string", "date-time"] }
    its(:to_hash) { should == {"type" => "string", "format" => "date-time"} }
  end

end