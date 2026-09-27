require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "quoted wraps text in typographic quotes and stays unsafe, so it is escaped" do
    assert_equal "“boots”", quoted("boots")
    assert_not quoted("<b>").html_safe?
  end

  test "ordinal" do
    assert_equal %w[1st 2nd 3rd 4th 11th 22nd], [ 1, 2, 3, 4, 11, 22 ].map { |n| ordinal(n) }
  end
end
