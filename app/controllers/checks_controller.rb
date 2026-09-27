# The whole app: one page with the form, and the results when there is
# something to check. The form submits with GET, as the 2015 original did, so
# a check is a link you can share: /?search=cyvasse+game&url=cyvasse.io
class ChecksController < ApplicationController
  # Echoing more than this back into the form serves nobody.
  ECHO_LIMIT = 300

  EXAMPLES = [
    { search: "play cyvasse online", url: "cyvasse.io" },
    { search: "hiking boots", url: "reddit.com" },
    { search: "cyvasse game", url: "cyvasse.io" }
  ].freeze

  def show
    @search = text_param(:search)
    @url = text_param(:url)
    return if @search.blank? && @url.blank?

    @check = PositionCheck.new(phrase: @search, site: @url)
    response.status = :unprocessable_content unless @check.valid?
  end

  private

  # A string or nothing: ?search[]=x arrives as an array, and is not a phrase.
  def text_param(name)
    value = params[name]
    value.is_a?(String) ? value.first(ECHO_LIMIT) : ""
  end
end
