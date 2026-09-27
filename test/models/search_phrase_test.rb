require "test_helper"

class SearchPhraseTest < ActiveSupport::TestCase
  test "cleans up the phrase like a search box" do
    phrase = SearchPhrase.new("  Cyvasse   GAME\t")
    assert phrase.valid?
    assert_equal "cyvasse game", phrase.text
    assert_equal "Cyvasse Game", phrase.title
    assert_equal %w[cyvasse game], phrase.ascii_words
  end

  test "reduces the words to ASCII for addresses, and never to nothing" do
    assert_equal %w[creme brulee], SearchPhrase.new("Crème brûlée!").ascii_words
    assert_equal %w[search], SearchPhrase.new("кофе").ascii_words
  end

  test "rejects an empty, overlong or symbol-only phrase" do
    assert_equal "Enter a search phrase.", SearchPhrase.new(" ").error
    assert_equal "Keep the phrase under 100 characters.", SearchPhrase.new("a" * 101).error
    assert_equal "Use at least one letter or number.", SearchPhrase.new("?!*").error
    assert SearchPhrase.new("a" * 100).valid?
  end
end
