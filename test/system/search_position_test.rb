require "application_system_test_case"

class SearchPositionTest < ApplicationSystemTestCase
  test "type a phrase and a site, see the position and the highlighted results" do
    visit root_path
    assert_selector "html.js"
    assert_selector "[data-demo-notice]", text: "not fetched from Google"

    fill_in "Search phrase", with: "hiking boots"
    fill_in "Your site", with: "https://www.reddit.com/"
    click_on "Check position"

    assert_current_path "/?search=hiking+boots&url=https%3A%2F%2Fwww.reddit.com%2F"
    assert_selector "[data-readout] .readout__number", text: "#4"
    assert_selector "[data-readout] h2", text: "reddit.com is 4th for “hiking boots”"
    assert_selector "li.result", count: 64
    assert_selector "li.result--yours", count: 2
    assert_field "Search phrase", with: "hiking boots"

    click_on "Jump to it"
    assert_equal "#result-4", page.evaluate_script("location.hash")
    highlight = page.evaluate_script("getComputedStyle(document.getElementById('result-4')).backgroundColor")
    plain = page.evaluate_script("getComputedStyle(document.getElementById('result-3')).backgroundColor")
    assert_not_equal plain, highlight, "your site should stand out from the results around it"
  end

  test "an example chip runs a check, including one where the site is not found" do
    visit root_path
    click_on "cyvasse game"
    assert_selector "[data-readout].readout--missing", text: "is not in the first 64 results"
    assert_no_selector "li.result--yours"
  end

  test "a bad address is explained next to the field" do
    visit root_path
    fill_in "Search phrase", with: "hiking boots"
    fill_in "Your site", with: "not a site"
    click_on "Check position"
    assert_selector "#url-error", text: "An address has no spaces in it."
    assert_no_selector "li.result"
  end

  test "a phone gets a stacked form and no sideways scroll, even on long results" do
    # Headless Chrome will not shrink a window below 500 px, so emulate the
    # phone screen instead, and check the emulation took.
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride",
      width: 375, height: 800, deviceScaleFactor: 2, mobile: true)
    visit root_path(search: "hiking boots", url: "reddit.com")
    assert_equal 375, page.evaluate_script("window.innerWidth")
    assert_selector "li.result", count: 64

    overflow = page.evaluate_script("document.documentElement.scrollWidth - document.documentElement.clientWidth")
    assert_equal 0, overflow, "the page scrolls sideways at 375 px"

    phrase = find_field("Search phrase").native.rect
    site = find_field("Your site").native.rect
    assert_operator phrase.y + phrase.height, :<=, site.y, "the site field sits under the phrase field on a phone"
  ensure
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
  end
end
