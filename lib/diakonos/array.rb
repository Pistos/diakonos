class Array
    def to_keychain_s
        chain_str = ""
        each do |key|
            key_str = key.keyString
            if key_str
                chain_str << key_str + " "
            else
                chain_str << key.to_s + " "
            end
        end
        return chain_str
    end
end

