# encoding: UTF-8

require "spec_helper"

describe "StringExtensions" do
  it "to_html" do
    require "RedCloth"
    {
      "h1. A Solution" => "<h1>A Solution</h1>",
      "I hated wrapping textilize around a string.\n\nIt always felt dirty." =>
        "<p>I hated wrapping textilize around a string.</p>\n<p>It always felt dirty.</p>",
      "I think _this_ is awesome" => "<p>I think <em>this</em> is awesome</p>",
      "Um... _*really*_, man" => "<p>Um&#8230; <em><strong>really</strong></em>, man</p>"
    }.each do |plain, html|
      expect(html).to eq plain.to_html
    end
  end
  
  it "to_html_lite" do
    require "RedCloth"
    {
      "I have no pee on me" => "I have no pee on me",
      "But I _do_ get Textile!" => "But I <em>do</em> get Textile!"
    }.each do |plain, html|
      expect(html).to eq plain.to_html(:lite)
    end
  end
  
  it "to_url" do
    {
      "<p>This has 100% too much    <em>formatting</em></p>" =>
        "this-has-100-percent-too-much-formatting",
      "Tea   &amp; crumpets &amp; <strong>cr&ecirc;pes</strong> for me!" => 
        "tea-and-crumpets-and-crepes-for-me",
      "The Suspense... Is... Killing Me" =>
        "the-suspense-dot-dot-dot-is-dot-dot-dot-killing-me",
      "How to use attr_accessible and attr_protected" =>
        "how-to-use-attr-accessible-and-attr-protected",
      "I'm just making sure there's nothing wrong with things!" =>
        "im-just-making-sure-theres-nothing-wrong-with-things"
    }.each do |html, plain|
      expect(plain).to eq html.to_url
    end
  end
  
  it "remove_formatting" do
    {
      "<p>This has 100% too much    <em>formatting</em></p>" =>
        "This has 100 percent too much formatting",
      "Tea   &amp; crumpets &amp; <strong>cr&ecirc;pes</strong> for me!" => 
        "Tea and crumpets and crepes for me"
    }.each do |html, plain|
      expect(plain).to eq html.remove_formatting
    end
  end
  
  it "strip_html_tags" do
    {
      "<h1><em>This</em> is good but <strong>that</strong> is better</h1>" =>
        "This is good but that is better",
      "<p>This is invalid XHTML but valid HTML, right?" =>
        "This is invalid XHTML but valid HTML, right?",
      "<p class='foo'>Everything goes!</p>" => "Everything goes!",
      "<ol>This is completely invalid and just plain wrong</p>" =>
        "This is completely invalid and just plain wrong"
    }.each do |html, plain|
      expect(plain).to eq html.strip_html_tags
    end
  end
  
  it "convert_accented_entities" do
    {
      "&aring;"  => "a",
      "&egrave;" => "e",
      "&icirc;"  => "i",
      "&Oslash;" => "O",
      "&uuml;"   => "u",
      "&Ntilde;" => "N",
      "&ccedil;" => "c"
    }.each do |entitied, plain|
      expect(plain).to eq entitied.convert_accented_entities
    end
  end
  
  it "convert_misc_entities" do
    {
      "America&#8482;" => "America(tm)",
      "Tea &amp; Sympathy" => "Tea and Sympathy",
      "To be continued&#8230;" => "To be continued...",
      "Foo&nbsp;Bar" => "Foo Bar",
      "100&#163;" => "100 pound",
      "&frac12; a dollar" => "half a dollar",
      "35&deg;" => "35 degrees"
    }.each do |entitied, plain|
      expect(plain).to eq entitied.convert_misc_entities
    end
  end
  
  it "convert_misc_characters" do
    {
      "Foo & bar make foobar" => "Foo and bar make foobar",
      "Breakdown #9" => "Breakdown number 9",
      "foo@bar.com" => "foo at bar dot com",
      "100% of yr love" => "100 percent of yr love",
      "Kisses are $3.25 each" => "Kisses are 3 dollars 25 cents each",
      "That CD is £3.25 plus tax" => "That CD is 3 pounds 25 pence plus tax",
      "This CD is ¥1000 instead" => "This CD is 1000 yen instead"
    }.each do |misc, plain|
      expect(plain).to eq misc.convert_misc_characters
    end
  end
  
  it "replace_whitespace" do
    {
      "this has     too much space" => "this has too much space",
      "\t\tThis is merely formatted with superfluous whitespace\n" =>
        " This is merely formatted with superfluous whitespace "
    }.each do |whitespaced, plain|
      expect(plain).to eq whitespaced.replace_whitespace
    end
    
    expect("now-with-more-hyphens").to eq "now with more hyphens".replace_whitespace("-")
  end
  
  it "collapse" do
    {
      "too      much space" => "too much space",
      "  at the beginning" => "at the beginning"
    }.each do |uncollapsed, plain|
      expect(plain).to eq uncollapsed.collapse
    end
    
    expect("now-with-hyphens").to eq "----now---------with-hyphens--------".collapse("-")
  end
end
