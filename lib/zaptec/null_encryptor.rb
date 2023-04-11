module Zaptec
  # rubocop:disable Lint/UnusedMethodArgument
  class NullEncryptor
    def encrypt(clear_text, key_provider: nil, cipher_options: {})
      clear_text
    end

    def decrypt(encrypted_text, key_provider: nil, cipher_options: {})
      encrypted_text
    end

    def encrypted?(_text)
      false
    end
  end
  # rubocop:enable Lint/UnusedMethodArgument
end
