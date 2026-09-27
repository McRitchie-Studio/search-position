require "test_helper"

class ChecksControllerTest < ActionDispatch::IntegrationTest
  test "the empty page has the two-field form, the examples and the demo notice, and no results" do
    get root_path
    assert_response :success
    assert_select "form[method=get][action='/']" do
      assert_select "label[for=search]", "Search phrase"
      assert_select "input#search[name=search]"
      assert_select "label[for=url]", "Your site"
      assert_select "input#url[name=url][inputmode=url]"
      assert_select "button[type=submit]", "Check position"
    end
    assert_select ".examples a.chip", ChecksController::EXAMPLES.size
    assert_select "a.chip[href=?]", "/?search=hiking+boots&url=reddit.com"
    assert_select "[data-demo-notice]", text: /not fetched from Google/
    assert_select "[data-readout]", 0
    assert_select ".result", 0
  end

  test "a check shows the position, then all 64 results with the site highlighted" do
    get root_path, params: { search: "hiking boots", url: "reddit.com" }
    assert_response :success
    assert_select "title", "#4 for “hiking boots” · Search Position"
    assert_select "[data-readout].readout--found" do
      assert_select ".readout__number", "#4"
      assert_select "h2", /reddit\.com\s+is 4th for “hiking boots”/
      assert_select ".readout__detail", /Page 1 of results\.\s+Also at 5\./
      assert_select "a[href='#result-4']", "Jump to it"
    end
    assert_select "ol.results__list", 7
    assert_select "ol.results__list[start='11']"
    assert_select "li.result", 64
    assert_select "li.result--yours[data-yours]", 2
    assert_select "li#result-4.result--yours .badge", "Your site"
    assert_select "li#result-5.result--yours"
    assert_select "li#result-3.result--yours", 0
    assert_select ".results__note", /Demo results/
    assert_select ".results a", 0, "demo addresses are made up, so they must not be links"
  end

  test "a site that is not in the list says so, as the original did" do
    get root_path, params: { search: "cyvasse game", url: "cyvasse.io" }
    assert_response :success
    assert_select "[data-readout].readout--missing h2", /cyvasse\.io\s+is not in the first 64 results/
    assert_select "li.result", 64
    assert_select "li.result--yours", 0
    assert_select "title", "Not in top 64 for “cyvasse game” · Search Position"
  end

  test "what the visitor typed is echoed back into the form" do
    get root_path, params: { search: "Play Cyvasse Online", url: "https://www.cyvasse.io/" }
    assert_select "input#search[value=?]", "Play Cyvasse Online"
    assert_select "input#url[value=?]", "https://www.cyvasse.io/"
    assert_select "[data-readout] h2", /cyvasse\.io\s+is 16th/
  end

  test "bad input answers 422 with a message under each field and no results" do
    get root_path, params: { search: "", url: "not a site" }
    assert_response :unprocessable_content
    assert_select "input#search[aria-invalid=true][aria-describedby=search-error]"
    assert_select "#search-error", "Enter a search phrase."
    assert_select "input#url[aria-invalid=true][aria-describedby=url-error]"
    assert_select "#url-error", "An address has no spaces in it."
    assert_select "[data-readout]", 0
    assert_select ".result", 0
  end

  test "only the bad field is flagged" do
    get root_path, params: { search: "hiking boots", url: "ftp://x.com" }
    assert_response :unprocessable_content
    assert_select "input#search[aria-invalid]", 0
    assert_select "#url-error", "Use an http or https address."
  end

  test "markup typed into either field comes back as text, never as HTML" do
    attack = %(<script>alert("x")</script><img src=x onerror=alert(1)>)
    get root_path, params: { search: attack, url: "example.com" }
    assert_response :success
    assert_not_includes response.body, "<script>alert"
    assert_not_includes response.body, "<img src=x"
    assert_includes response.body, "&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt;"
    assert_select "input#search[value=?]", attack

    get root_path, params: { search: "boots", url: %("><script>alert(1)</script>) }
    assert_response :unprocessable_content
    assert_not_includes response.body, "<script>alert(1)"
  end

  test "a field sent as an array or a hash is treated as empty, not an error page" do
    get "/?search[]=a&url=example.com"
    assert_response :unprocessable_content
    assert_select "#search-error", "Enter a search phrase."

    get "/?search[x]=a&url[x]=b"
    assert_response :success, "both fields empty is just the blank form"
    assert_select "[data-readout]", 0
  end

  test "an enormous field is cut short before it is echoed" do
    get root_path, params: { search: "a" * 5_000, url: "example.com" }
    assert_response :unprocessable_content
    assert_select "input#search" do |inputs|
      assert_equal ChecksController::ECHO_LIMIT, inputs.first["value"].length
    end
  end

  test "every page credits the original and sets no cookie" do
    get root_path
    assert_select "footer a[href=?]", "https://github.com/amcritchie/google-search-position"
    assert_nil response.headers["set-cookie"]
  end

  test "the health check answers" do
    get rails_health_check_path
    assert_response :success
  end
end
