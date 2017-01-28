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
      expect(extract("label :thing, :the_foo, :foo, :en => 'Foo'")).to eq({'asdf.labels.foo' => "Foo"})
      expect(extract("f.label :the_foo, :foo, :en => 'Foo'")).to eq({'asdf.labels.foo' => "Foo"})
      expect(extract("label_tag :the_foo, :foo, :en => 'Foo'")).to eq({'asdf.labels.foo' => "Foo"})
    end

    it "should infer the key from the method if not provided" do
      expect(extract("label :thing, :the_foo, :en => 'Foo'")).to eq({'asdf.labels.the_foo' => "Foo"})
      expect(extract("f.label :the_foo, :en => 'Foo'")).to eq({'asdf.labels.the_foo' => "Foo"})
      expect(extract("label_tag :the_foo, :en => 'Foo'")).to eq({'asdf.labels.the_foo' => "Foo"})
    end

    it "should skip label calls with non-symbol keys (i.e. just a standard label)" do
      expect(extract("label :thing, :the_foo, 'foo'")).to eq({})
      expect(extract("f.label :the_foo, 'foo'")).to eq({})
      expect(extract("label_tag :thing, 'foo'")).to eq({})
    end

    it "should not auto-scope absolute keys" do
      expect(extract("label :thing, :the_foo, :'#foo', :en => 'Foo'")).to eq({"foo" => "Foo"})
      expect(extract("f.label :the_foo, :'#foo', :en => 'Foo'")).to eq({"foo" => "Foo"})
      expect(extract("label_tag :the_foo, :'#foo', :en => 'Foo'")).to eq({"foo" => "Foo"})
    end
  end

  context "nesting" do
    it "should ignore i18n calls within i18n method definitions" do
      expect(extract("def t(*args); other.t *args; end")).to eq({})
    end
  end

  context "scoping" do
    it "should auto-scope relative keys to the current scope" do
      expect(extract("t 'foo', 'Foo'")).to eq({'asdf.foo' => "Foo"})
    end

    it "should not auto-scope absolute keys" do
      expect(extract("t '#foo', 'Foo'")).to eq({'foo' => "Foo"})
    end

    it "should not auto-scope keys with I18n as the receiver" do
      expect(extract("I18n.t 'foo', 'Foo'")).to eq({'foo' => 'Foo'})
    end

    it "should auto-scope plugin registration" do
      expect(extract("Canvas::Plugin.register('dim_dim', :web_conferencing, {:name => lambda{ t :name, \"DimDim\" }})")).to eq(
          {'plugins.dim_dim.name' => "DimDim"}
      )
    end

    it "should require explicit keys if a key is provided and there is no scope" do
      expect { extract("t 'foo', 'Foo'", I18nliner::Scope.root) }.to raise_error /ambiguous translation key/
    end

    it "should not require explicit keys if the key is inferred and there is no scope" do
      expect(extract("t 'Foo'", I18nliner::Scope.root)).to eq({'foo_f44ad75d' => 'Foo'})
    end

    it "should not scope inferred keys" do
      expect(extract("t 'Hello World'")).to eq({'hello_world_e2033670' => 'Hello World'})
    end
  end

  context "sanitization" do
    it "should reject stuff that looks sufficiently html-y" do
      expect { extract "t 'dude', 'this is <em>important</em>'" }.to raise_error /html tags in default translation/
    end

    it "should generally be ok with angle brackets" do
      expect(extract("t 'obvious', 'TIL 1 < 2'")).to eq({'asdf.obvious' => 'TIL 1 < 2'})
      expect(extract("t 'email', 'please enter an email, e.g. Joe User <joe@example.com>'")).to eq({'asdf.email' => 'please enter an email, e.g. Joe User <joe@example.com>'})
    end
  end
end
