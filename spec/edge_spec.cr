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

      edge.check_secret?("not likely").should be_false
      edge.check_secret?(secret).should be_true
    end

    it "generates a token" do
      edge = Generator.edge
      secret = edge.secret
      edge.save!
      expected = "#{edge.id}_#{secret}"
      edge.token(Generator.authenticated_user).should eq expected
    end
  end
end
