require 'tmpdir'
require 'open-uri'
require 'zip/zipfilesystem'

# Original Author: Dave McCrory in repo cf-meta
module CloudFoundry
  class App
    PACK_EXCLUSION_GLOBS = ['..', '.', '*~', '#*#', '*.log']
    DEFAULT_CF = ".cloudfoundry.com"
    MAX_NAME_TRIES = 10

    attr_accessor :name_changed, :display_name

    def self.is_available_app_name? name
      begin
        url = "http://#{name}#{DEFAULT_CF}"
        puts "Checking #{url} if available"
        response = RestClient.get url
      rescue Exception => ex
        puts "#{url} is available "
        return true
      end
      return false
    end

    def self.find_available_app_name external_email, external_app_name
      # http://www.ietf.org/rfc/rfc2396.txt
      # alpha    = lowalpha | upalpha
      # alphanum = alpha | digit
      # domainlabel   = alphanum | alphanum *( alphanum | "-" ) alphanum
      generated_name =  external_app_name.downcase.gsub(/[^-\w]/, '-')

      unless CloudFoundry::App.is_available_app_name?(generated_name)
        email_parts = external_email.split '@'
        # Nice name is not available so give them a generated semi safe name
        generated_name = "#{external_app_name}-#{email_parts.first}"
        counter = 0
        while (!CloudFoundry::App.is_available_app_name?(generated_name))
          counter += 1
          if (counter > MAX_NAME_TRIES)
            generated_name = nil
            break
          end
          generated_name = "#{external_app_name}-#{email_parts.first}-#{counter}"
        end
      end
      generated_name
    end

    def initialize(vmc_client, meta)
      @name_changed = false
      @vmcclient = vmc_client
      @app_meta = meta
      @base_name = @app_meta.display_name
      build_manifest!
    end

    def create(options={})
      begin
        @vmcclient.create_app(@manifest["name"], @manifest)
      rescue RuntimeError => ex
        if (ex.message =~ /Error 701/)
          pick_another_name_if_taken = options[:pick_another_name_if_taken] == true ? true : false
          tries_left = options[:tries_left] || MAX_NAME_TRIES
          #puts "uri = #{@uri} failed pick_another_name_if_taken = #{pick_another_name_if_taken} and tries_left=#{tries_left}"
          if pick_another_name_if_taken && tries_left > 0
            index = MAX_NAME_TRIES - tries_left + 1
            change_name! "#{@base_name}-#{index}"
            create(:pick_another_name_if_taken => true, :tries_left => tries_left - 1)
          else
            # Format is "Error #{parsed_body[:code]}: #{desc}"
            raise "App Url: #{@uri} is already taken"
          end
        else
          raise ex
        end
      end
    end

    def delete()
      @vmcclient.delete_app(@manifest["name"])
    end

    def copy_code()
      extracted_dir = "#{Dir.tmpdir}/#{@app_meta.repo_name}-#{@app_meta.git_commit}"

      unless (Dir.exists? extracted_dir)
        puts "Downloading to directory #{extracted_dir}"
        tmp_file = "#{Dir.tmpdir}raw-#{@app_meta.display_name}.zip"
        zip_url = "#{@app_meta.git_repo}/zipball/#{@app_meta.git_branch}"
        get(tmp_file, zip_url)
        #extracts to extracted_dir
        unpack(tmp_file, Dir.tmpdir)
        extracted_dir
      else
        puts "Great news the source repo directory #{extracted_dir} already exists"
      end

      unless get_files_to_pack(extracted_dir).empty?
        zipfile = "#{Dir.tmpdir}/#{@app_meta.display_name}.zip"
        if  File::exists?("#{zipfile}")
          puts "We already have the packed zip #{zipfile}"
        else
          pack(extracted_dir, zipfile)
        end
        @vmcclient.upload_app(@app_meta.display_name, zipfile)
      end
    end

    def exists?
      begin
        read_info
        return true
      rescue VMC::Client::NotFound => ex
        return false
      end
    end

    def start()
      read_info()

      if @info[:state] != 'STARTED' then
        @info[:state] = 'STARTED'
        @vmcclient.update_app(@app_meta.display_name, @info)
      end
    end

    def read_info
      @info = @vmcclient.app_info(@app_meta.display_name)
      @app_meta.app_urls = @info[:uris]
      @info
    end

    #Helper method to download zips from Github
    def get(name,path='/')
      open(name, 'wb') do |getfile|
        getfile.print open(path).read
      end
    end

    private
      def get_files_to_pack(dir)
        Dir.glob("#{dir}/**/*", File::FNM_DOTMATCH).select do |f|
          process = true
          PACK_EXCLUSION_GLOBS.each { |e| process = false if File.fnmatch(e, File.basename(f)) }
          process && File.exists?(f)
        end
      end

      def pack(dir, zipfile)
        File::delete("#{zipfile}") if File::exists?("#{zipfile}")
        Zip::ZipFile::open(zipfile, true) do |zf|
          get_files_to_pack(dir).each do |f|
            zf.add(f.sub("#{dir}/",''), f)
          end
        end
      end

      def unpack(file, dest)
        Zip::ZipFile.foreach(file) do |zentry|
          epath = "#{dest}/#{zentry}"
          dirname = File.dirname(epath)
          FileUtils.mkdir_p(dirname) unless File.exists?(dirname)
          zentry.extract(epath) unless File.exists?(epath)
        end
      end

      def build_manifest!
        @display_name = @app_meta.display_name
        @uri = "#{@display_name}#{DEFAULT_CF}"

        @manifest = {
           "env" => @app_meta.env_array,
           "name"=> @display_name,
           "staging"=>{"framework"=>@app_meta.framework, "runtime"=>@app_meta.runtime},
           "uris"=>[@uri],
           "instances"=>1,
           "resources"=>{"memory"=>@app_meta.memory}
        }
      end

      def change_name! new_name
        @app_meta.display_name = new_name
        @name_changed = true
        build_manifest!
      end
  end
end