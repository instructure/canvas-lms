require File.expand_path(File.dirname(__FILE__) + '/swagger_helper')
require 'argument_view'

describe ArgumentView do
  context "type splitter" do
    let(:view) { ArgumentView.new "" }

    it "accepts no type" do
      view.split_type_desc("").should ==
        [ArgumentView::DEFAULT_TYPE, ArgumentView::DEFAULT_DESC]
    end

    it "parses type with no desc" do
      view.split_type_desc("[String]").should ==
        ["[String]", ArgumentView::DEFAULT_DESC]
    end

    it "parses type and desc" do
      view.split_type_desc("[String] desc ription").should ==
        ["[String]", "desc ription"]
    end

    it "parses complex types" do
      view.split_type_desc("[[String], [Date]]").should ==
        ["[[String], [Date]]", ArgumentView::DEFAULT_DESC]
    end
  end

  context "line parser" do
    let(:view) { ArgumentView.new "" }

    it "compacts whitespace" do
      parsed = view.parse_line("arg  \t[String] desc")
      parsed.should == ["arg [String] desc", "arg", "[String]", "desc"]
    end

    it "parses without desc" do
      parsed = view.parse_line("arg [String]")
      parsed.should == ["arg [String]", "arg", "[String]", ArgumentView::DEFAULT_DESC]
    end

    it "parses without type or desc" do
      parsed = view.parse_line("arg")
      parsed.should == ["arg", "arg", ArgumentView::DEFAULT_TYPE, ArgumentView::DEFAULT_DESC]
    end
  end

  context "with types, enums, description" do
    let(:view) { ArgumentView.new %{arg [Optional, String, "val1"|"val2"] argument} }

    it "has enums" do
      view.enums.should == ["val1", "val2"]
    end

    it "has types" do
      view.types.should == ["String"]
    end

    it "has a description" do
      view.desc.should == "argument"
    end
  end

  context "with optional arg" do
    let(:view) { ArgumentView.new %{arg [String]} }

    it "is optional" do
      view.optional?.should be_true
    end
  end

  context "with required arg" do
    let(:view) { ArgumentView.new %{arg [Required, String]} }

    it "is required" do
      view.required?.should be_true
    end
  end
end