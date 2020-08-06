require "./helper"

module PlaceOS::Model
  describe Metadata do
    it "saves control_system metadata" do
      control_system = Generator.control_system.save!
      meta = Generator.metadata(name: "test", parent: control_system.id.as(String)).save!

      control_system.metadata.first.id.should eq meta.id
      meta_find = Metadata.find!(meta.id.as(String))
      meta_find.control_system!.id.should eq control_system.id

      control_system.destroy
    end

    it "saves zone metadata" do
      zone = Generator.zone.save!
      meta = Generator.metadata(parent: zone.id.as(String)).save!

      zone.metadata.first.id.should eq meta.id
      meta_find = Metadata.find!(meta.id.as(String))
      meta_find.zone!.id.should eq zone.id

      zone.destroy
    end

    describe "for" do
      it "fetches metadata for a parent" do
        parent = Generator.zone.save!
        parent_id = parent.id.as(String)
        5.times do
          Generator.metadata(parent: parent_id).save!
        end
        Metadata.for(parent_id).to_a.size.should eq 5
        parent.destroy
      end
    end

    describe "build_metadata" do
      it "builds a response of metadata for a parent" do
        parent = Generator.zone.save!
        parent_id = parent.id.as(String)
        5.times do
          Generator.metadata(parent: parent_id).save!
        end
        Metadata.build_metadata(parent_id).size.should eq 5
        parent.destroy
      end
    end
  end
end
