require "json"

record PlaceOS::Model::Version, service : String, commit : String, build_time : String, version : String do
  include JSON::Serializable
end
