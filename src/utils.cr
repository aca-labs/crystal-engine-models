require "json"
require "semantic_version"

# Create a serialisation method with subset defined by fields
# Pass a serialise method to fields if the field class does not define a to_json method
# method_name : Symbol
# fields      : Enumerable(Symbol | NamedTuple(field: Symbol, serialise: Symbol))
macro subset_json(method_name, fields)
 {% fields = fields.resolve if fields.is_a?(Path) %}
  def {{ method_name.id }}
    {
      {% for field in fields %}
        {% if field.is_a?(NamedTupleLiteral) %}
          {{ field[:field].id }}: self.{{ field[:field].id }}.try &.{{ field[:serialise].id }},
        {% elsif field.is_a?(SymbolLiteral) %}
          {{ field.id }}: self.{{ field.id }},
        {% else %}
          {{ raise "expected Enumerable(Symbol | NamedTuple(field: Symbol, serialise: Symbol)), got element #{field}" }}
        {% end %}
      {% end %}
    }.to_json
  end
end

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

  def self.from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node) : SemanticVersion
    unless node.is_a?(YAML::Nodes::Scalar)
      node.raise "Expected scalar, not #{node.class}"
    end
    SemanticVersion.parse(node.value.to_s)
  end

  def self.to_yaml(value : SemanticVersion, yaml : YAML::Nodes::Builder)
    yaml.scalar(value.to_s)
  end
end

module Scrypt::Converter
  def self.from_json(value : JSON::PullParser) : Scrypt::Password
    Scrypt::Password.new(value.read_string)
  end

  def self.to_json(value : Scrypt::Password, json : JSON::Builder)
    json.string(value.to_s)
  end

  def self.from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node) : Scrypt::Password
    unless node.is_a?(YAML::Nodes::Scalar)
      node.raise "Expected scalar, not #{node.class}"
    end
    Scrypt::Password.new(node.value.to_s)
  end

  def self.to_yaml(value : Scrypt::Password, yaml : YAML::Nodes::Builder)
    yaml.scalar(value.to_s)
  end
end
