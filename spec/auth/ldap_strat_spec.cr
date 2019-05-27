require "../helper"

module Engine::Model
  describe LdapStrat do
    it "saves a LdapStrat" do
      strat = Generator.ldap_strat.save!
      LdapStrat.find(strat.id).should_not be_nil
    end
  end
end
