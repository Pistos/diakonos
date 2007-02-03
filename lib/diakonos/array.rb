class Array
    def to_keychain_s
        chain_str = ""
        each do |key|
            chain_str << key.keyString + " "
        end
        return chain_str
    end
end

