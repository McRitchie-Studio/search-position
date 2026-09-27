class ApplicationController < ActionController::Base
  # No allow_browser gate: the checker should open on any browser. The page is
  # plain HTML and CSS; nothing depends on the script.

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
