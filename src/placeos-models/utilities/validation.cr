require "uri"

module PlaceOS::Model::Validation
  def self.valid_uri?(uri : String) : URI?
    return if uri.blank?
    parsed = URI.parse(uri)
    parsed unless parsed.scheme.presence.nil? || parsed.host.presence.nil?
  rescue
    nil
  end
end
