require 'test_helper'

class RawOutputHelperTest < ActionView::TestCase

  def setup
    @string = "hello"
  end

  test "raw returns the safe string" do
    result = raw(@string)
    assert_equal @string, result
    assert result.html_safe?
  end

  test "raw handles nil values correctly" do
    assert_equal "", raw(nil)
  end
end
