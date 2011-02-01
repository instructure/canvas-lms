require 'test_helper'

class OutputSafetyTest < ActiveSupport::TestCase
  def setup
    @string = "hello"
    @object = Class.new(Object) do
      def to_s
        "other"
      end
    end.new
  end

  test "A string is unsafe by default" do
    assert !@string.html_safe?
  end

  test "A string can be marked safe" do
    string = @string.html_safe
    assert string.html_safe?
  end

  test "Marking a string safe returns the string" do
    assert_equal @string, @string.html_safe
  end

  test "A fixnum is safe by default" do
    assert 5.html_safe?
  end

  test "An object is unsafe by default" do
    assert !@object.html_safe?
  end

  test "Adding an object to a safe string returns a safe string" do
    string = @string.html_safe
    string << @object

    assert_equal "helloother", string
    assert string.html_safe?
  end

  test "Adding a safe string to another safe string returns a safe string" do
    @other_string = "other".html_safe
    string = @string.html_safe
    @combination = @other_string + string

    assert_equal "otherhello", @combination
    assert @combination.html_safe?
  end

  test "Adding an unsafe string to a safe string escapes it and returns a safe string" do
    @other_string = "other".html_safe
    @combination = @other_string + "<foo>"
    @other_combination = @string + "<foo>"

    assert_equal "other&lt;foo&gt;", @combination
    assert_equal "hello<foo>", @other_combination

    assert @combination.html_safe?
    assert !@other_combination.html_safe?
  end

  test "Concatting safe onto unsafe yields unsafe" do
    @other_string = "other"

    string = @string.html_safe
    @other_string.concat(string)
    assert !@other_string.html_safe?
  end

  test "Concatting unsafe onto safe yields escaped safe" do
    @other_string = "other".html_safe
    string = @other_string.concat("<foo>")
    assert_equal "other&lt;foo&gt;", string
    assert string.html_safe?
  end

  test "Concatting safe onto safe yields safe" do
    @other_string = "other".html_safe
    string = @string.html_safe

    @other_string.concat(string)
    assert @other_string.html_safe?
  end

  test "Concatting safe onto unsafe with << yields unsafe" do
    @other_string = "other"
    string = @string.html_safe

    @other_string << string
    assert !@other_string.html_safe?
  end

  test "Concatting unsafe onto safe with << yields escaped safe" do
    @other_string = "other".html_safe
    string = @other_string << "<foo>"
    assert_equal "other&lt;foo&gt;", string
    assert string.html_safe?
  end

  test "Concatting safe onto safe with << yields safe" do
    @other_string = "other".html_safe
    string = @string.html_safe

    @other_string << string
    assert @other_string.html_safe?
  end

  test "Concatting a fixnum to safe always yields safe" do
    string = @string.html_safe
    string = string.concat(13)
    assert_equal "hello".concat(13), string
    assert string.html_safe?
  end
end
