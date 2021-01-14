require "digest/md5"

require "./helper"

module PlaceOS::Model
  describe User do
    describe "#save" do
      it "saves a User" do
        user = Generator.user.save!
        User.find!(user.id.as(String)).id.should eq user.id
      end

      it "sets email digest on save" do
        user = Generator.user
        expected_digest = Digest::MD5.hexdigest(user.email)

        user.email_digest.should be_nil
        user.save!

        user.persisted?.should be_true
        user.email_digest.should eq expected_digest
      end
    end

    describe "validations" do
      it "ensure associated authority" do
        user = Generator.user
        user.authority_id = ""
        user.valid?.should be_false
        user.errors.first.field.should eq :authority_id
      end

      it "ensure presence of user's email" do
        user = Generator.user
        user.email = ""
        user.valid?.should be_false
        user.errors.first.field.should eq :email
      end
    end

    describe "mass assignment" do
      it "prevents escalation of privilege" do
        user = Generator.user(admin: false, support: false).save!
        user.assign_attributes_from_json({support: true}.to_json)
        user.is_support?.should be_false
        user.assign_attributes_from_json({sys_admin: true}.to_json)
        user.is_admin?.should be_false
        user.assign_attributes_from_json({sys_admin: true, support: true}.to_json)
        user.is_admin?.should be_false
        user.is_support?.should be_false
      end
    end

    it "#as_public_json" do
      user = Generator.user.save!
      public_user = JSON.parse(user.as_public_json.to_json).as_h
      public_attributes = User::PUBLIC_DATA.to_a.map do |field|
        field.is_a?(NamedTuple) ? field[:field].to_s : field.to_s
      end

      public_user.keys.sort.should eq public_attributes.sort
    end

    it "#as_admin_json" do
      user = Generator.user.save!
      admin_user = JSON.parse(user.as_admin_json.to_json).as_h

      admin_attributes = User::ADMIN_DATA.to_a.map do |field|
        field.is_a?(NamedTuple) ? field[:field].to_s : field.to_s
      end

      admin_user.keys.sort.should eq admin_attributes.sort
    end

    it "should create a new user with a password" do
      existing = Authority.find_by_domain("localhost")
      authority = existing || Generator.authority.save!
      json = {
        name:         Faker::Name.name,
        email:        Random.rand(9999).to_s + Faker::Internet.email,
        authority_id: authority.id,
        sys_admin:    true,
        support:      true,
        password:     "p@ssw0rd",
      }.to_json

      user = Model::User.from_json(json)
      user.password_digest.should eq(nil)
      user.password.should eq("p@ssw0rd")
      user.save!
      user.password_digest.should_not eq(nil)
      user.password.should eq(nil)
    end
  end
end
