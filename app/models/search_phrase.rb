# What the visitor typed into "Search phrase", cleaned up the way a search box
# would: trimmed, spaces collapsed, lower case. It also knows the URL-safe
# spellings of itself that the demo results are made from.
class SearchPhrase
  MAX_LENGTH = 100

  attr_reader :text, :error

  def initialize(input)
    @text = input.to_s.gsub(/[[:space:]]+/, " ").strip.downcase
    @error = check
  end

  def valid? = error.nil?

  def to_s = text

  # "Cyvasse Game"
  def title
    text.split(" ").map { |word| word[0].upcase + word[1..] }.join(" ")
  end

  # ["cyvasse", "game"]: the words reduced to plain ASCII letters and digits,
  # for the parts of an address. A phrase with none (say, all Cyrillic) still
  # gets one, so every address is well formed.
  def ascii_words
    words = I18n.transliterate(text).scan(/[a-z0-9]+/)
    words.empty? ? [ "search" ] : words
  end

  private

  def check
    return "Enter a search phrase." if text.empty?
    return "Keep the phrase under #{MAX_LENGTH} characters." if text.length > MAX_LENGTH
    "Use at least one letter or number." unless text.match?(/[[:alnum:]]/)
  end
end
