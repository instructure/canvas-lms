require 'test_helper'

class DeprecatedOutputSafetyTest < ActiveSupport::TestCase
  def setup
    @string = "hello"
  end

  test "A string can be marked safe using html_safe!" do
    assert_deprecated do
      @string.html_safe!
      assert @string.html_safe?
    end
  end

  test "Marking a string safe returns the string using html_safe!" do
    assert_deprecated do
      assert_equal @string, @string.html_safe!
    end
  end

  test "Adding a safe string to another safe string returns a safe string using html_safe!" do
    assert_deprecated do
      @other_string = "other".html_safe!
      @string.html_safe!
      @combination = @other_string + @string

      assert_equal "otherhello", @combination
      assert @combination.html_safe?
    end
  end

  test "Adding an unsafe string to a safe string returns an unsafe string using html_safe!" do
    assert_deprecated do
      @other_string = "other".html_safe!
      @combination = @other_string + "<foo>"
      @other_combination = @string + "<foo>"

      assert_equal "other<foo>", @combination
      assert_equal "hello<foo>", @other_combination

      assert !@combination.html_safe?
      assert !@other_combination.html_safe?
    end
  end

  test "Concatting safe onto unsafe yields unsafe using html_safe!" do
    assert_deprecated do
      @other_string = "other"
      @string.html_safe!

      @other_string.concat(@string)
      assert !@other_string.html_safe?
    end
  end

  test "Concatting unsafe onto safe yields unsafe using html_safe!" do
    assert_deprecated do
      @other_string = "other".html_safe!
      string = @other_string.concat("<foo>")
      assert_equal "other<foo>", string
      assert !string.html_safe?
    end
  end

  test "Concatting safe onto safe yields safe using html_safe!" do
    assert_deprecated do
      @other_string = "other".html_safe!
      @string.html_safe!

      @other_string.concat(@string)
      assert @other_string.html_safe?
    end
  end

  test "Concatting safe onto unsafe with << yields unsafe using html_safe!" do
    assert_deprecated do
      @other_string = "other"
      @string.html_safe!

      @other_string << @string
      assert !@other_string.html_safe?
    end
  end

  test "Concatting unsafe onto safe with << yields unsafe using html_safe!" do
    assert_deprecated do
      @other_string = "other".html_safe!
      string = @other_string << "<foo>"
      assert_equal "other<foo>", string
      assert !string.html_safe?
    end
  end

  test "Concatting safe onto safe with << yields safe using html_safe!" do
    assert_deprecated do
      @other_string = "other".html_safe!
      @string.html_safe!

      @other_string << @string
      assert @other_string.html_safe?
    end
  end

  test "Concatting a fixnum to safe always yields safe using html_safe!" do
    assert_deprecated do
      @string.html_safe!
      @string.concat(13)
      assert_equal "hello".concat(13), @string
      assert @string.html_safe?
    end
  end
end
