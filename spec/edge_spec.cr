require "./helper"

module PlaceOS::Model
  describe Edge do
    it "saves an Edge" do
      edge = Generator.edge.save!

      edge.should_not be_nil
      edge.persisted?.should be_true
      Edge.find!(edge.id.as(String)).id.should eq edge.id
    end

    it "encrypts secrets on save" do
      edge = Generator.edge
      Encryption.is_encrypted?(edge.secret).should be_false
      edge.save!
      Encryption.is_encrypted?(edge.secret).should be_true
    end

    it "validates secrets" do
      edge = Generator.edge
      secret = edge.secret
      edge.encrypt!

      edge.valid?("not likely").should be_false
      edge.valid?(secret).should be_true
    end
  end
end
