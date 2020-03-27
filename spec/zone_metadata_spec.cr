require "./helper"

module PlaceOS::Model
  describe Zone do
    it "saves zone metadata" do
      zone = Generator.zone
      zone.save!

      meta = Zone::Metadata.new
      meta.zone_id = zone.id
      meta.name = "test"

      begin
        meta.save!
      rescue e : RethinkORM::Error::DocumentInvalid
        inspect_error(e)
        raise e
      end

      zone.metadata.to_a.first.id.should eq(meta.id)
      meta_find = ZoneMetadata.find(meta.id).not_nil!
      meta_find.zone.not_nil!.id.should eq(zone.id)
    end
  end
end
