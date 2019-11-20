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
      settings = Generator.settings(settings_string: unencrypted).save!
      encrypted = settings.settings_string.as(String)

      encrypted.should_not eq unencrypted
      encrypted.should start_with '\e'
    end

    it "generates top-level settings keys on save" do
      unencrypted = %({"secret_key": "secret1234"})
      settings = Generator.settings(settings_string: unencrypted).save!
      settings.keys.should eq ["secret_key"]
    end
  end

  pending "#decrypt_for!" do
    mock_settings = [
      {Encryption::Level::None, %({"sla": "99.?"})},
      {Encryption::Level::Support, %({"whales": "victor mcwhale"})},
      {Encryption::Level::Admin, %({"tax_haven": "seychelles"})},
      {Encryption::Level::NeverDisplay, %({"secret_key": "secret1234"})},
    ]

    it "decrypts for unprivileged" do
      sys = Generator.control_system
      user = Generator.user

      sys.settings = mock_settings.dup
      sys.save!

      encrypted_settings = sys.settings.not_nil!
      encrypted_settings.all? { |s| is_encrypted?(s[1].as(String)) }

      sys.decrypt_for!(user)

      is_encrypted?(sys.settings_at(Encryption::Level::None).as(String)).should be_false
      is_encrypted?(sys.settings_at(Encryption::Level::Support).as(String)).should be_true
      is_encrypted?(sys.settings_at(Encryption::Level::Admin).as(String)).should be_true
      is_encrypted?(sys.settings_at(Encryption::Level::NeverDisplay).as(String)).should be_true
    end

    it "decrypts for support" do
      sys = Generator.control_system
      user = Generator.user
      user.support = true

      sys.settings = mock_settings.dup
      sys.save!

      encrypted_settings = sys.settings.not_nil!
      encrypted_settings.all? { |s| is_encrypted?(s[1].as(String)) }

      sys.decrypt_for!(user)

      is_encrypted?(sys.settings_at(Encryption::Level::None).as(String)).should be_false
      is_encrypted?(sys.settings_at(Encryption::Level::Support).as(String)).should be_false
      is_encrypted?(sys.settings_at(Encryption::Level::Admin).as(String)).should be_true
      is_encrypted?(sys.settings_at(Encryption::Level::NeverDisplay).as(String)).should be_true
    end

    it "decrypts for admin" do
      sys = Generator.control_system
      user = Generator.authenticated_user

      sys.settings = mock_settings.dup
      sys.save!

      encrypted_settings = sys.settings.not_nil!
      encrypted_settings.all? { |s| is_encrypted?(s[1].as(String)) }

      sys.decrypt_for!(user)

      is_encrypted?(sys.settings_at(Encryption::Level::None).as(String)).should be_false
      is_encrypted?(sys.settings_at(Encryption::Level::Support).as(String)).should be_false
      is_encrypted?(sys.settings_at(Encryption::Level::Admin).as(String)).should be_false
      is_encrypted?(sys.settings_at(Encryption::Level::NeverDisplay).as(String)).should be_true
    end
  end
end
