require "json"

record PlaceOS::Model::Version, service : String, commit : String, build_time : Int64, version : String do
  include JSON::Serializable
end
