module ApplicationHelper
  ORIGINAL_REPO = "https://github.com/amcritchie/google-search-position".freeze

  # “cyvasse game”, in typographic quotes. Escaped like any other text.
  def quoted(text)
    "“#{text}”"
  end

  # 1 → "1st", 22 → "22nd"
  def ordinal(number)
    number.to_i.ordinalize
  end
end
