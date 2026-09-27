require "test_helper"

class PositionCheckTest < ActiveSupport::TestCase
  test "a site the results already hold is found where it is, every time it appears" do
    check = PositionCheck.new(phrase: "hiking boots", site: "https://www.reddit.com/")
    assert check.valid?
    assert_equal [ 4, 5 ], check.matches.map(&:position)
    assert_equal 4, check.position
    assert check.results[3].yours?
    assert_equal 1, check.results[3].page
  end

  test "a site the results do not hold is placed once, at a seeded spot" do
    check = PositionCheck.new(phrase: "play cyvasse online", site: "cyvasse.io")
    assert_equal 16, check.position
    assert_equal [ 16 ], check.matches.map(&:position)
    placed = check.results[15]
    assert_equal "https://cyvasse.io/", placed.url
    assert_equal "Play Cyvasse Online | Cyvasse", placed.title
    assert_equal 2, placed.page
    assert_equal 64, check.results.size
  end

  test "the same site typed differently gets the same answer" do
    positions = [ "cyvasse.io", "https://www.cyvasse.io/", "CYVASSE.IO" ].map do |site|
      PositionCheck.new(phrase: "Play Cyvasse  Online", site: site).position
    end
    assert_equal [ 16 ], positions.uniq
  end

  test "sometimes the site is not in the first 64 results" do
    check = PositionCheck.new(phrase: "cyvasse game", site: "cyvasse.io")
    assert_not check.found?
    assert_nil check.position
    assert_empty check.matches
    assert_equal 64, check.results.size
  end

  test "about one site in five is left out, across many checks" do
    checks = (1..200).map { |n| PositionCheck.new(phrase: "phrase #{n}", site: "site#{n}.example") }
    missing = checks.count { |check| !check.found? }
    assert_includes 20..60, missing, "expected about 40 of 200 left out"
    assert(checks.all? { |check| check.position.nil? || check.position.between?(1, 64) })
  end

  test "positions are numbered 1 to 64 in order" do
    check = PositionCheck.new(phrase: "hiking boots", site: "reddit.com")
    assert_equal (1..64).to_a, check.results.map(&:position)
  end

  test "a breadcrumb shows the host without www and the path segments" do
    result = PositionCheck::Result.new(position: 1, url: "https://www.example.com/a/b?q=1", title: "t", snippet: "s", yours: false)
    assert_equal "example.com › a › b", result.breadcrumb
  end

  test "an invalid check has errors and no results" do
    check = PositionCheck.new(phrase: "", site: "not a site")
    assert_not check.valid?
    assert_equal({ phrase: "Enter a search phrase.", site: "An address has no spaces in it." }, check.errors)
    assert_empty check.results
  end
end
