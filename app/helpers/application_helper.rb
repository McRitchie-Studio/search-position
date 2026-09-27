module ApplicationHelper
  # An outbound link that opens in a new tab without handing the new page a
  # handle on this one. The arrow is decoration, so screen readers skip it.
  def external_link(label, url, **options)
    link_to url, target: "_blank", rel: "noopener", **options do
      safe_join([ label, tag.span("↗", class: "arrow", aria: { hidden: true }) ], " ")
    end
  end
end
