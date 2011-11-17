require 'tmpdir'
require 'open-uri'
require 'zip/zipfilesystem'

# Original Author: Dave McCrory in repo cf-meta
module CloudFoundry
  class App
    PACK_EXCLUSION_GLOBS = ['..', '.', '*~', '#*#', '*.log']
    DEFAULT_CF = ".cloudfoundry.com"

    def initialize(vmc_client, meta)
      @vmcclient = vmc_client
      @meta = meta
      @uri = "#{@meta.display_name}#{DEFAULT_CF}"

      @manifest = {"env" => @meta.env_array, "name"=>@meta.display_name, "staging"=>{"framework"=>@meta.framework, "runtime"=>@meta.runtime}, "uris"=>[@uri], "instances"=>1, "resources"=>{"memory"=>@meta.memory}}
    end

    def create()
      @vmcclient.create_app(@manifest["name"], @manifest)
    end

    def copy_code()
      extracted_dir = "#{Dir.tmpdir}/#{@meta.repo_name}-#{@meta.git_commit}"

      unless (Dir.exists? extracted_dir)
        tmp_file = "#{Dir.tmpdir}raw-#{@meta.display_name}.zip"
        zip_url = "#{@meta.git_repo}/zipball/#{@meta.git_branch}"
        get(tmp_file, zip_url)
        #extracts to extracted_dir
        unpack(tmp_file, Dir.tmpdir)
        extracted_dir
      end

      unless get_files_to_pack(extracted_dir).empty?
        zipfile = "#{Dir.tmpdir}/#{@meta.display_name}.zip"
        pack(extracted_dir, zipfile)
        @vmcclient.upload_app(@meta.display_name, zipfile)
      end
    end

    def start()
      read_info()

      if @info[:state] != 'STARTED' then
        @info[:state] = 'STARTED'
        @vmcclient.update_app(@meta.display_name, @info)
      end
    end

    def read_info
      @info = @vmcclient.app_info(@meta.display_name)
      @meta.app_urls = @info[:uris]
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
  end
end