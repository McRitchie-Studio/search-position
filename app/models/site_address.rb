# The site the visitor asks about, read the way people actually type one:
# "cyvasse.io", "www.cyvasse.io", "https://cyvasse.io/", "cyvasse.io/rules".
#
# A result counts as the site when
#   - its host is the same, ignoring a leading "www." and letter case, or is a
#     subdomain of it ("wikipedia.org" covers "en.wikipedia.org"; the reverse
#     does not hold), and
#   - when the site names a path, the result is that page or below it, on a
#     whole-segment boundary ("/blog" covers "/blog" and "/blog/post", not
#     "/blogger").
# The scheme, port, a trailing slash, the query and the fragment never matter.
#
# The 2015 original stripped "http://" and "www." and then asked whether the
# result's address merely contained what was left, so "go.com" matched
# "https://www.lego.com/".
class SiteAddress
  MAX_LENGTH = 200
  HOST = /\A(?=.{1,253}\z)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}\z/
  SCHEME = %r{\A([a-z][a-z0-9+.-]*)://}i

  attr_reader :input, :host, :path, :error

  # limit caps what a visitor types; a result's address is read without it,
  # since "https://" can carry a site at the limit over it.
  def initialize(input, limit: MAX_LENGTH)
    @input = input.to_s.strip
    @limit = limit
    @error = read
  end

  def valid? = error.nil?

  # "cyvasse.io/rules"
  def to_s = "#{host}#{path}"

  # The site's own home (or page), as a result would show it.
  def url = "https://#{host}#{path.presence || "/"}"

  # "Cyvasse", from the first label of the host.
  def name = host.split(".").first.capitalize

  def matches?(address)
    return false unless valid?

    other = address.is_a?(SiteAddress) ? address : SiteAddress.new(address, limit: nil)
    other.valid? && same_site?(other.host) && covers?(other.path)
  end

  private

  def same_site?(other_host)
    other_host == host || other_host.end_with?(".#{host}")
  end

  def covers?(other_path)
    path.empty? || other_path == path || other_path.start_with?("#{path}/")
  end

  def read
    return "Enter your site's address." if input.empty?
    return "Keep the address under #{@limit} characters." if @limit && input.length > @limit
    return "An address has no spaces in it." if input.match?(/\s/)

    scheme = input[SCHEME, 1]
    return "Use an http or https address." if scheme && !scheme.casecmp?("http") && !scheme.casecmp?("https")

    authority, rest = input.sub(SCHEME, "").split(%r{(?=[/?#])}, 2)
    host = authority.to_s.sub(/:\d{1,5}\z/, "").downcase.delete_suffix(".").delete_prefix("www.")
    return "Enter an address like example.com." unless host.match?(HOST)

    @host = host
    @path = rest.to_s.sub(/[?#].*\z/m, "").squeeze("/").delete_suffix("/")
    nil
  end
end
