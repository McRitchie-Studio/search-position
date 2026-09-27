require "test_helper"

class SiteAddressTest < ActiveSupport::TestCase
  test "reads the ways people type an address down to one host and path" do
    {
      "cyvasse.io" => "cyvasse.io",
      "www.cyvasse.io" => "cyvasse.io",
      "https://www.cyvasse.io/" => "cyvasse.io",
      "HTTP://CYVASSE.IO" => "cyvasse.io",
      "cyvasse.io:8080/" => "cyvasse.io",
      "cyvasse.io/rules/" => "cyvasse.io/rules",
      "cyvasse.io/rules?tab=2#setup" => "cyvasse.io/rules",
      "cyvasse.io?ref=x" => "cyvasse.io",
      "cyvasse.io//a//b" => "cyvasse.io/a/b",
      "  cyvasse.io  " => "cyvasse.io"
    }.each do |typed, read|
      site = SiteAddress.new(typed)
      assert site.valid?, "#{typed.inspect}: #{site.error}"
      assert_equal read, site.to_s, typed
    end
  end

  test "matches regardless of scheme, www, trailing slash, query and fragment" do
    site = SiteAddress.new("cyvasse.io")
    %w[
      https://cyvasse.io/ http://www.cyvasse.io https://www.cyvasse.io/play?x=1 https://cyvasse.io/#top
      https://CYVASSE.io/rules
    ].each { |url| assert site.matches?(url), url }
  end

  test "a bare domain covers its subdomains, a subdomain does not cover its parent" do
    assert SiteAddress.new("wikipedia.org").matches?("https://en.wikipedia.org/wiki/Cyvasse")
    assert_not SiteAddress.new("en.wikipedia.org").matches?("https://wikipedia.org/")
    assert_not SiteAddress.new("en.wikipedia.org").matches?("https://de.wikipedia.org/")
  end

  test "a path covers that page and the pages below it, on whole segments" do
    site = SiteAddress.new("https://www.cyvasse.io/blog/")
    assert site.matches?("https://cyvasse.io/blog")
    assert site.matches?("https://cyvasse.io/blog/opening-moves")
    assert_not site.matches?("https://cyvasse.io/blogger")
    assert_not site.matches?("https://cyvasse.io/")
    assert_not site.matches?("https://cyvasse.io/about/blog")
  end

  test "regression: the 2015 substring match counted any address that contained the site" do
    site = SiteAddress.new("go.com")
    assert_not site.matches?("https://www.lego.com/"), "lego.com is not go.com"
    assert_not site.matches?("https://go.com.evil.example/"), "a host that merely starts with the site"
    assert_not site.matches?("https://example.com/?next=go.com"), "the site named in a query string"
  end

  test "rejects what is not a web address, with a message for the form" do
    {
      "" => "Enter your site's address.",
      "   " => "Enter your site's address.",
      "cyvasse io" => "An address has no spaces in it.",
      "localhost" => "Enter an address like example.com.",
      "ftp://cyvasse.io" => "Use an http or https address.",
      "cyvasse_io.com" => "Enter an address like example.com.",
      "-bad-.com" => "Enter an address like example.com.",
      "cyvasse.i" => "Enter an address like example.com.",
      "#{"a" * 190}.example.com" => "Keep the address under 200 characters."
    }.each do |typed, message|
      site = SiteAddress.new(typed)
      assert_not site.valid?, typed
      assert_equal message, site.error, typed
    end
  end

  test "an invalid site matches nothing" do
    assert_not SiteAddress.new("nope").matches?("https://nope/")
    assert_not SiteAddress.new("cyvasse.io").matches?("not a url")
  end

  test "names itself and its home page for a placed result" do
    site = SiteAddress.new("www.cyvasse.io/rules/")
    assert_equal "Cyvasse", site.name
    assert_equal "https://cyvasse.io/rules", site.url
    assert_equal "https://cyvasse.io/", SiteAddress.new("cyvasse.io").url
  end
end
