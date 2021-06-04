require "json"

record(PlaceOS::Model::Version,
  service : String,
  commit : String,
  version : String,
  platform_version : String = {{ env("PLACE_VERSION") || "DEV" }},
  build_time : String,
) do
  include JSON::Serializable
end
