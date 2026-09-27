# One check: a phrase, a site, and where the site lands in the phrase's demo
# results.
#
# When a result already belongs to the site (ask about "wikipedia.org" and the
# Wikipedia article is there), that is its position. Otherwise the demo places
# one page of the site into the list, at a spot seeded from the phrase and the
# site, and one time in five leaves it out altogether, so "Not in the first 64
# results" is a real outcome too. The page says all of this is simulated.
class PositionCheck
  ABSENT_ONE_IN = 5
  Result = Data.define(:position, :url, :title, :snippet, :yours) do
    alias_method :yours?, :yours

    # 1 for results 1-10, 2 for 11-20, ...
    def page = (position - 1) / 10 + 1

    # "en.wikipedia.org › wiki › Cyvasse_game": how a results page shows an address.
    def breadcrumb
      uri = URI.parse(url)
      [ uri.host.delete_prefix("www."), *uri.path.split("/").reject(&:empty?) ].join(" › ")
    rescue URI::InvalidURIError
      url
    end
  end

  attr_reader :phrase, :site

  def initialize(phrase:, site:)
    @phrase = SearchPhrase.new(phrase)
    @site = SiteAddress.new(site)
  end

  def valid? = phrase.valid? && site.valid?

  def errors
    { phrase: phrase.error, site: site.error }.compact
  end

  def results
    return [] unless valid?

    @results ||= begin
      listed = DemoSearch.new(phrase).results.dup
      if listed.none? { |result| site.matches?(result.url) } && (spot = placement)
        listed[spot - 1] = DemoSearch::Result.new(
          url: site.url,
          title: "#{phrase.title} | #{site.name}",
          snippet: "#{site.name} on #{phrase.text}: what we offer, how it works and how to get started. Visit #{site.host} to learn more."
        )
      end

      listed.each_with_index.map do |result, index|
        Result.new(position: index + 1, yours: site.matches?(result.url), **result.to_h)
      end.freeze
    end
  end

  def matches = results.select(&:yours?)

  # The site's best (1-based) position, or nil when it is not in the list.
  def position = matches.first&.position

  def found? = !position.nil?

  def result_count = DemoSearch::RESULT_COUNT

  private

  # Where the demo puts the site, or nil when it leaves it out. Skewed toward
  # the top, the way a site that bothers to check usually sits.
  def placement
    random = Random.new(DemoSearch.seed("placement", phrase.text, site.to_s))
    return nil if random.rand(ABSENT_ONE_IN).zero?

    1 + (random.rand**1.6 * result_count).floor
  end
end
