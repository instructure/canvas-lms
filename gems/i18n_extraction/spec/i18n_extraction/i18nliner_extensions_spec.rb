require 'spec_helper'
require 'i18n_extraction/i18nliner_extensions'

describe I18nliner::Extractors::RubyExtractor do
  def extract(source, scope = I18nliner::Scope.new("asdf"))
    sexps = RubyParser.new.parse(source)
    extractor = I18nliner::Extractors::RubyExtractor.new(sexps, scope)
    translations = []
    extractor.each_translation { |translation| translations << translation }
    Hash[translations]
  end


  context "labels" do
    it "should interpret symbol names as the key" do
      extract("label :thing, :the_foo, :foo, :en => 'Foo'").should == {'asdf.labels.foo' => "Foo"}
      extract("f.label :the_foo, :foo, :en => 'Foo'").should == {'asdf.labels.foo' => "Foo"}
      extract("label_tag :the_foo, :foo, :en => 'Foo'").should == {'asdf.labels.foo' => "Foo"}
    end

    it "should infer the key from the method if not provided" do
      extract("label :thing, :the_foo, :en => 'Foo'").should == {'asdf.labels.the_foo' => "Foo"}
      extract("f.label :the_foo, :en => 'Foo'").should == {'asdf.labels.the_foo' => "Foo"}
      extract("label_tag :the_foo, :en => 'Foo'").should == {'asdf.labels.the_foo' => "Foo"}
    end

    it "should skip label calls with non-symbol keys (i.e. just a standard label)" do
      extract("label :thing, :the_foo, 'foo'").should == {}
      extract("f.label :the_foo, 'foo'").should == {}
      extract("label_tag :thing, 'foo'").should == {}
    end

    it "should not auto-scope absolute keys" do
      extract("label :thing, :the_foo, :'#foo', :en => 'Foo'").should == {"foo" => "Foo"}
      extract("f.label :the_foo, :'#foo', :en => 'Foo'").should == {"foo" => "Foo"}
      extract("label_tag :the_foo, :'#foo', :en => 'Foo'").should == {"foo" => "Foo"}
    end
  end

  context "nesting" do
    it "should ignore i18n calls within i18n method definitions" do
      extract("def t(*args); other.t *args; end").should == {}
    end
  end

  context "scoping" do
    it "should auto-scope relative keys to the current scope" do
      extract("t 'foo', 'Foo'").should == {'asdf.foo' => "Foo"}
    end

    it "should not auto-scope absolute keys" do
      extract("t '#foo', 'Foo'").should == {'foo' => "Foo"}
    end

    it "should not auto-scope keys with I18n as the receiver" do
      extract("I18n.t 'foo', 'Foo'").should == {'foo' => 'Foo'}
    end

    it "should auto-scope plugin registration" do
      extract("Canvas::Plugin.register('dim_dim', :web_conferencing, {:name => lambda{ t :name, \"DimDim\" }})").should ==
          {'plugins.dim_dim.name' => "DimDim"}
    end

    it "should require explicit keys if a key is provided and there is no scope" do
      lambda { extract("t 'foo', 'Foo'", I18nliner::Scope.root) }.should raise_error /ambiguous translation key/
    end

    it "should not require explicit keys if the key is inferred and there is no scope" do
      extract("t 'Foo'", I18nliner::Scope.root).should == {'foo_f44ad75d' => 'Foo'}
    end

    it "should not scope inferred keys" do
      extract("t 'Hello World'").should == {'hello_world_e2033670' => 'Hello World'}
    end
  end

  context "sanitization" do
    it "should reject stuff that looks sufficiently html-y" do
      lambda { extract "t 'dude', 'this is <em>important</em>'" }.should raise_error /html tags in default translation/
    end

    it "should generally be ok with angle brackets" do
      extract("t 'obvious', 'TIL 1 < 2'").should == {'asdf.obvious' => 'TIL 1 < 2'}
      extract("t 'email', 'please enter an email, e.g. Joe User <joe@example.com>'").should == {'asdf.email' => 'please enter an email, e.g. Joe User <joe@example.com>'}
    end
  end
end
