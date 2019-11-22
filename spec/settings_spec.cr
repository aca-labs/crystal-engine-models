require "./helper"

module ACAEngine::Model
  describe Settings do
    it "saves a settings" do
      settings = Generator.settings
      begin
        settings.save!
      rescue e : RethinkORM::Error::DocumentInvalid
        inspect_error(e)
        raise e
      end

      settings.should_not be_nil
      settings.persisted?.should be_true
      settings.id.as(String).should start_with "sets-"
    end

    it "encrypts on save" do
      unencrypted = %({"secret_key": "secret1234"})
      settings = Generator.settings(settings_string: unencrypted, encryption_level: Encryption::Level::Admin).save!
      encrypted = settings.settings_string.as(String)

      encrypted.should_not eq unencrypted
      encrypted.should start_with '\e'
    end

    it "generates top-level settings keys on save" do
      unencrypted = %({"secret_key": "secret1234"})
      settings = Generator.settings(settings_string: unencrypted).save!
      settings.keys.should eq ["secret_key"]
    end

    it "creates versions on updates to the master Settings" do
      settings_history = ["a: 0\n", "a: 1\n", "a: 2\n", "a: 3\n"]
      settings = Generator.settings(
        encryption_level: Encryption::Level::None,
        settings_string: settings_history.first
      ).save!

      settings_history[1..].each do |string|
        # 1 second sleep as the resolution of timestamps are terrible
        sleep 1
        settings.settings_string = string
        settings.update!
      end

      settings.history.map(&.any["a"]).should eq [0, 1, 2]
    end
  end

  describe "#decrypt_for" do
    {
      {Encryption::Level::None, %({"sla": "99.?"})},
      {Encryption::Level::Support, %({"whales": "victor mcwhale"})},
      {Encryption::Level::Admin, %({"tax_haven": "seychelles"})},
      {Encryption::Level::NeverDisplay, %({"secret_key": "secret1234"})},
    }.each do |level, string|
      it "decrypts for #{level}" do
        user = Generator.user
        support = Generator.user(support: true)
        admin = Generator.user(admin: true)

        settings = Settings.new(encryption_level: level, parent_id: "1234", settings_string: string)
        settings.encrypt!

        case level
        when Encryption::Level::None
          settings.decrypt_for(user).should eq string
          settings.decrypt_for(support).should eq string
          settings.decrypt_for(admin).should eq string
          is_encrypted?(settings.decrypt_for(user)).should be_false
          is_encrypted?(settings.decrypt_for(support)).should be_false
          is_encrypted?(settings.decrypt_for(admin)).should be_false
        when Encryption::Level::Support
          settings.decrypt_for(user).should_not eq string
          settings.decrypt_for(support).should eq string
          settings.decrypt_for(admin).should eq string
          is_encrypted?(settings.decrypt_for(user)).should be_true
          is_encrypted?(settings.decrypt_for(support)).should be_false
          is_encrypted?(settings.decrypt_for(admin)).should be_false
        when Encryption::Level::Admin
          settings.decrypt_for(user).should_not eq string
          settings.decrypt_for(support).should_not eq string
          settings.decrypt_for(admin).should eq string
          is_encrypted?(settings.decrypt_for(user)).should be_true
          is_encrypted?(settings.decrypt_for(support)).should be_true
          is_encrypted?(settings.decrypt_for(admin)).should be_false
        when Encryption::Level::NeverDisplay
          settings.decrypt_for(user).should_not eq string
          settings.decrypt_for(support).should_not eq string
          settings.decrypt_for(admin).should_not eq string
          is_encrypted?(settings.decrypt_for(user)).should be_true
          is_encrypted?(settings.decrypt_for(support)).should be_true
          is_encrypted?(settings.decrypt_for(admin)).should be_true
        end
      end
    end
  end
end
