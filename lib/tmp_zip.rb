require 'tmpdir'
require 'open-uri'
require 'zip/zipfilesystem'

module TmpZip
  PACK_EXCLUSION_GLOBS = ['..', '.', '*~', '#*#', '*.log']

  #Helper method to download zips from Github
  def get(name,path='/')
    open(name, 'wb') do |getfile|
      getfile.print open(path).read
    end
  end

  def unpack(file, dest)
    actual_dir = nil
    Zip::ZipFile.foreach(file) do |zentry|
      epath = "#{dest}/#{zentry}"
      # The first item is the directory so get its name
      actual_dir = zentry.name unless actual_dir
      dirname = File.dirname(epath)
      FileUtils.mkdir_p(dirname) unless File.exists?(dirname)
      zentry.extract(epath) unless File.exists?(epath)
    end
    actual_dir
  end

  def pack(dir, zipfile)
    File::delete("#{zipfile}") if File::exists?("#{zipfile}")
    Zip::ZipFile::open(zipfile, true) do |zf|
      get_files_to_pack(dir).each do |f|
        zf.add(f.sub("#{dir}/",''), f)
      end
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


end