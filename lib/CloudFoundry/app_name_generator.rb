module CloudFoundry
  class AppNameGenerator
    MAX_NAME_TRIES = 10

    attr_accessor :name, :base_name, :base_index, :clean_name

    def initialize name, stem, external_email, cloud=".cloudfoundry.com"
      @name = name
      @stem = stem
      @external_email = external_email
      @user_handle = nil
      parts = @external_email.split('@')
      @user_handle = parts.first if parts.length > 0
      @generated_name = nil
      @clean_name = generate_clean_name

      @cloud = cloud
      @tries = 0
      @base_name = @clean_name.gsub /-?(\d+)$/, ''
      @base_index = $1.to_i  || 0
    end


    def next
      if @tries < MAX_NAME_TRIES
        @tries += 1
        if @user_handle && @base_index == 0 && @tries == 1
          "#{@base_name}-#{@user_handle}"
        else
          "#{@base_name}-#{@base_index + @tries}"
        end
      else
        nil
      end
    end

    def self.is_valid_subdomain name
      ((name =~  /^[a-zA-Z][\-a-zA-Z0-9]+$/) == 0)
    end

    def find_available_app_name
      generated_name = @clean_name
      while (!is_available_app_name?(generated_name))
        generated_name = self.next
        break if generated_name.nil?
      end
      @generated_name = generated_name
    end

    private
      # Returns a valid subdomain
      # http://www.ietf.org/rfc/rfc2396.txt
      # alpha    = lowalpha | upalpha
      # alphanum = alpha | digit
      # domainlabel   = alphanum | alphanum *( alphanum | "-" ) alphanum
      def generate_clean_name
        clean_name =  @name.downcase.gsub(/[^-\w]+/m, '-').gsub(/_/, '-')  #underscores are not allowed
        # Cannot start with -
        if clean_name =~ /^-/
          clean_name = @stem + clean_name
        end
        # Also weird to end with '-'
        clean_name = clean_name[0..clean_name.length-2] if clean_name =~ /-$/
        clean_name
      end

      # Cheks by issuing HTTP requests
      # Needs to be optimized. Do map instead
      def is_available_app_name? name
        unless name.blank?
          begin
            url = "http://#{name}#{@cloud}"
            puts "Checking #{url} if available"
            response = RestClient.get url
          rescue RestClient::ResourceNotFound => ex
            puts "#{url} is available"
            return true
          end
        end
        return false
      end
  end
end