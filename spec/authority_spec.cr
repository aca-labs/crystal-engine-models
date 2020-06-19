require "./helper"

module PlaceOS::Model
  Spec.before_each do
    Authority.clear
  end

  describe Authority do
    it "saves an Authority" do
      inst = Generator.authority.save!
      Authority.find!(inst.id.as(String)).id.should eq inst.id
    end

    it "only saves the domain's host" do
      authority = Authority.new
      authority.domain = "https://localhost:8080"
      authority.domain.should eq "localhost"
    end

    it "find_by_domain" do
      domain = "http://localhost:8080"
      authority = Generator.authority(domain).save!
      found = Authority.find_by_domain(domain)
      found.try(&.id).should eq authority.id
    end

    describe "destroy relations" do
      it "removes dependent saml authentications" do
        auth = Generator.authority.save!
        strat = Generator.adfs_strat(authority: auth).save!
        auth.destroy
        SamlAuthentication.find(strat.id.as(String)).should be_nil
      end

      it "removes dependent ldap authentications" do
        auth = Generator.authority.save!
        strat = Generator.ldap_strat(authority: auth).save!
        auth.destroy
        LdapAuthentication.find(strat.id.as(String)).should be_nil
      end

      it "removes dependent oauth authentications" do
        auth = Generator.authority.save!
        strat = Generator.oauth_strat(authority: auth).save!
        auth.destroy
        OAuthAuthentication.find(strat.id.as(String)).should be_nil
      end

      it "removes dependent users" do
        auth = Generator.authority.save!
        user = Generator.user(authority: auth).save!
        auth.destroy
        User.find(user.id.as(String)).should be_nil
      end
    end
  end
end
