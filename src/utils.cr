require "json"
require "semantic_version"

# Reopen the SemanticVersion class
struct SemanticVersion
  # Allows serialization to rethinkDB query language
  def to_reql
    JSON::Any.new(self.to_s)
  end
end

# Serialization for SemanticVersion fields of models
module SemanticVersion::Converter
  def self.from_json(value : JSON::PullParser) : SemanticVersion
    SemanticVersion.parse(value.read_string)
  end

  def self.to_json(value : SemanticVersion, json : JSON::Builder)
    json.string(value.to_s)
  end
end
