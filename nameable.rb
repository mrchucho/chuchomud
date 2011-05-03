module Nameable
    def name
        @name
    end
    def name=(name)
        @name = name
    end
	def named?(name)
        return false unless defined?(@name)
		myname = @name.downcase
		name.strip!
		name.downcase!
		# full match
		return true if myname == name
		# partial match
		# hrm # return true if name.empty?
		# matches if any of the words START with a match
		if myname.index(name) then
			myname.split(' ').each do |word|
				return true if word.index(name)==0
			end
		end
		false
	end
end

