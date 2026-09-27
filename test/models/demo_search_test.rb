require "test_helper"

class DemoSearchTest < ActiveSupport::TestCase
  def results_for(text) = DemoSearch.new(SearchPhrase.new(text)).results

  test "gives 64 results, every one a well-formed https address with a title and snippet" do
    results = results_for("cyvasse game")
    assert_equal 64, results.size
    results.each do |result|
      uri = URI.parse(result.url)
      assert_equal "https", uri.scheme, result.url
      assert SiteAddress.new(result.url).valid?, result.url
      assert result.title.present?
      assert result.snippet.present?
      assert_no_match(/%\{/, [ result.url, result.title, result.snippet ].join, "a placeholder was left unfilled")
    end
  end

  test "one phrase always gives the same list; another phrase gives another" do
    assert_equal results_for("cyvasse game"), results_for("  Cyvasse Game ")
    assert_not_equal results_for("cyvasse game").map(&:url), results_for("hiking boots").map(&:url)
  end

  test "fills the placeholders from the phrase" do
    urls = results_for("hiking boots").map(&:url)
    assert_includes urls, "https://en.wikipedia.org/wiki/Hiking_boots"
    assert_includes urls, "https://www.amazon.com/s?k=hiking+boots"
    assert(urls.any? { |url| url.include?("/r/hikingboots/") })
  end

  test "top-ranked pages tend to stay near the top" do
    urls = results_for("hiking boots").first(10).map(&:url)
    assert(urls.any? { |url| url.include?("wikipedia.org") }, "Wikipedia should be on page one")
  end

  test "the data file has enough rows and only known placeholders" do
    assert_operator DemoSearch.templates.size, :>=, DemoSearch::RESULT_COUNT
  end

  test "a malformed data file raises when it loads, naming the row" do
    Tempfile.create([ "demo_web", ".yml" ]) do |file|
      rows = Array.new(64) { { "url" => "https://x.com/%{slug}", "title" => "t", "snippet" => "s", "rank" => 0.5 } }
      rows[3]["title"] = "%{nope}"
      file.write(rows.to_yaml)
      file.flush
      error = assert_raises(ArgumentError) { DemoSearch.load_templates(file.path) }
      assert_match(/row 4: unknown placeholder nope/, error.message)
    end
  end

  test "a data file with too few rows or a rank out of range raises" do
    Tempfile.create([ "demo_web", ".yml" ]) do |file|
      file.write([ { "url" => "https://x.com/", "title" => "t", "snippet" => "s", "rank" => 0.5 } ].to_yaml)
      file.flush
      assert_raises(ArgumentError) { DemoSearch.load_templates(file.path) }
    end
    Tempfile.create([ "demo_web", ".yml" ]) do |file|
      file.write(Array.new(64) { { "url" => "https://x.com/", "title" => "t", "snippet" => "s", "rank" => 2 } }.to_yaml)
      file.flush
      error = assert_raises(ArgumentError) { DemoSearch.load_templates(file.path) }
      assert_match(/row 1: rank must be 0..1/, error.message)
    end
  end
end
