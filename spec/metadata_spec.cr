require "./helper"

module PlaceOS::Model
  describe Metadata do
    it "saves control_system metadata" do
      control_system = Generator.control_system.save!
      meta = Generator.metadata(name: "test", parent: control_system.id.as(String)).save!

      control_system.metadata.first.id.should eq meta.id
      meta_find = Metadata.find!(meta.id.as(String))
      meta_find.control_system.not_nil!.id.should eq control_system.id
    end

    it "saves zone metadata" do
      zone = Generator.zone.save!
      meta = Generator.metadata(name: "test", parent: zone.id.as(String)).save!

      zone.metadata.first.id.should eq meta.id
      meta_find = Metadata.find!(meta.id.as(String))
      meta_find.zone.not_nil!.id.should eq zone.id
    end

    pending "for" do
      it "fetches metadata for a parent" do
      end
    end

    pending "build_metadata" do
      it "builds a response of metadata for a parent" do
      end
    end
  end
end
