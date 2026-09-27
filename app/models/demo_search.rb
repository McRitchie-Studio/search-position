require "digest"

# A believable page of search results for a phrase, made up on the spot from
# config/demo_web.yml. Nothing is fetched: the retired Google API the 2015
# original used is gone, and a showcase should not scrape a live engine.
#
# The list is deterministic. Every random choice (the order, the ids, the
# small numbers) comes from a generator seeded with a hash of the phrase, so a
# phrase gives the same 64 results on every visit, on every machine.
class DemoSearch
  RESULT_COUNT = 64
  JITTER = 0.35
  PLACEHOLDERS = %w[phrase Title slug joined plus under word id n].freeze
  PLACEHOLDER = /%\{(\w+)\}/
  ID_CHARS = [ *"a".."z", *"0".."9" ].freeze

  Result = Data.define(:url, :title, :snippet)
  Template = Data.define(:url, :title, :snippet, :rank)

  def self.templates
    @templates ||= load_templates(Rails.root.join("config/demo_web.yml"))
  end

  # Reads and checks the data file; a bad row raises at boot, not on a visit.
  def self.load_templates(path)
    rows = YAML.safe_load_file(path)
    raise ArgumentError, "#{path}: needs at least #{RESULT_COUNT} rows" unless rows.is_a?(Array) && rows.size >= RESULT_COUNT

    rows.each_with_index.map do |row, index|
      template = Template.new(**row.transform_keys(&:to_sym))
      [ template.url, template.title, template.snippet ].each do |text|
        unknown = text.to_s.scan(PLACEHOLDER).flatten - PLACEHOLDERS
        raise ArgumentError, "#{path} row #{index + 1}: unknown placeholder #{unknown.first}" if unknown.any?
      end
      raise ArgumentError, "#{path} row #{index + 1}: rank must be 0..1" unless template.rank.is_a?(Numeric) && template.rank.between?(0, 1)

      template
    end.freeze
  rescue ArgumentError, TypeError => e
    raise ArgumentError, e.message.start_with?(path.to_s) ? e.message : "#{path}: #{e.message}"
  end

  # A number from a hash of the given parts: the seed for everything random.
  def self.seed(*parts)
    Digest::SHA256.digest(parts.join("\n")).unpack1("Q>")
  end

  attr_reader :phrase

  def initialize(phrase)
    @phrase = phrase
  end

  def results
    @results ||= begin
      random = Random.new(self.class.seed("results", phrase.text))
      ordered = self.class.templates.sort_by.with_index { |template, index| [ template.rank + random.rand * JITTER, index ] }
      ordered.first(RESULT_COUNT).map do |template|
        Result.new(url: fill(template.url, random), title: fill(template.title, random), snippet: fill(template.snippet, random))
      end.freeze
    end
  end

  private

  def fill(text, random)
    text.gsub(PLACEHOLDER) { value(Regexp.last_match(1), random) }
  end

  def value(name, random)
    words = phrase.ascii_words
    case name
    when "phrase" then phrase.text
    when "Title" then phrase.title
    when "slug" then words.join("-")
    when "joined" then words.join
    when "plus" then words.join("+")
    when "under" then words.join("_").capitalize
    when "word" then words.max_by(&:length)
    when "id" then Array.new(8) { ID_CHARS[random.rand(ID_CHARS.size)] }.join
    when "n" then (2 + random.rand(8)).to_s
    end
  end
end
