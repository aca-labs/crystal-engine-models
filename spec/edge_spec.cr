require "./helper"

module PlaceOS::Model
  describe Edge do
    it "saves an Edge" do
      edge = Generator.edge.save!

      edge.should_not be_nil
      edge.persisted?.should be_true
      Edge.find!(edge.id.as(String)).id.should eq edge.id
    end
  end
end
