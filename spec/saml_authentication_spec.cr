require "./helper"

module PlaceOS::Model
  describe SamlAuthentication do
    describe "attribute_statements" do
      it "#assign_attributes_from_json" do
        saml = SamlAuthentication.new
        saml.attribute_statements = {"hello" => ["world"]}
        saml.assign_attributes_from_json({attribute_statements: {hello: ["world"], world: ["hello"]}}.to_json)
        saml.attribute_statements.should eq({"world" => ["hello"], "hello" => ["world"]})
        saml.assign_attributes_from_json({attribute_statements: {world: ["hello"]}}.to_json)
        saml.attribute_statements.should eq({"world" => ["hello"]})
      end
    end
  end
end
