#!/usr/bin/env ruby

require 'syck'

class Key
  def initialize()
    @hash = Hash.new
    @all = Array.new
    @hosts = Array.new
    @resources = Array.new
    @modules = Array.new
    @other = Array.new
  end
    
  def hash
    return @hash
  end
  
  def all
    return @all
  end
  
  def hosts
    return @hosts
  end
  
  def resources
    return @resources
  end
  
  def modules
    return @modules
  end
  
  def other
    return @other
  end
  
  def add_refs(ref, dir)
    if dir.include?("hosts")
      @hosts = @hosts << ref
    elsif dir.include?("resource")
      @resources = @resources << ref
    elsif dir.include?("module")
      @modules = @modules << ref
    else
      @other = @other << ref
    end
    @all = @all << ref
    return @all
  end
  
  def find_key(key)
    value = @hash.fetch(key)
    puts "#{key}"
    value.print_refs("")
    value.print(1)
  end
  
  def print_refs(str)
    @count= @hosts.length
    if @count > 0
      puts "#{str}| host refs:#{@count}"
      @hosts.each do |host|
         puts "#{str}|    @#{host}"
      end 
    end
    
    @count=@resources.length
    if @count > 0
      puts "#{str}| resource refs:#{@count}"
      @resources.each do |resource|
        puts "#{str}|    @#{resource}"
      end
    end
    @count=@modules.length
    if @count > 0
      puts "#{str}| module refs:#{@count}"
      @modules.each do |modules|
        puts "#{str}|    @#{modules}"
      end
    end
    @count=@other.length
    if @count > 0
      puts "#{str}| other refs:#{@count}"
      @other.each do |other|
        puts "#{str}|    @#{other}"
      end
    end
  end
  
  def print(level)
    if !@hash.empty?
      num = 0
      str = ""
      value_str = ""
      while num < level do
        str = str + "|   "
        value_str = value_str + "____"
        num = num+1
      end
      space = "\n" + str
      @hash.each_pair do |key, value|
        if key.kind_of?(String)
          if key.include? "BEGIN"
            this_str = str + key
            #this_str = value_str + key
            this_str = this_str.gsub(/[^__]^/, space)
            this_str.strip
            puts "#{this_str}"
          else
           key = key.gsub(/\n+\s*/m, space)
           key.strip
            puts "#{str}#{key}:"
          # puts "#{value_str}#{key}:"
          end
        else
           puts "#{str}#{key}:"
        #  puts "#{value_str}#{key}:"
        end
        #if value.hash.empty?
        #if level >= 1
          value.print_refs(str)
        #end
        value.print(level+1)
      end
    end
  end
  
  def add_value(key, value, ref, dir)
    @hash.store(key, Key.new()) unless @hash.has_key?(key)
    key_obj = @hash.fetch(key)
    key_obj.add_refs(ref, dir)
    key_hash = key_obj.hash
    
    if value.kind_of?(Hash)
      value.each do |hash_key, val|
        key_obj.add_value(hash_key, val, ref, dir)
      end
    elsif value.kind_of?(Array)
      value.collect
      value.each do |val|
      	add_value(key, val, ref, dir)
      end
    else
      key_hash.store(value, Key.new()) unless key_hash.has_key?(value)
      v = key_hash.fetch(value)
      v.add_refs(ref, dir)
    end
  end
  
end


class Run
  def self.use_yaml(file, dir)
    yp = YAML::Syck::Parser.new( {} ) 
    if File.file?(file)
      if @data = yp.load( File::open( file ).read)
        @host, @this = file.split(/[\.\_.*]/)
        @data.each_pair do |key, value|
          @@k.add_value(key, value, @host, dir)
        end
      end
    else
      puts "fail file"
    end
  end

  def self.start(dir, key)
    @@k = Key.new()
    Dir.chdir("/etc/puppet/hieradata")
    open_dir(dir)
    if key == nil
      @@k.print(0)
    else
      @@k.find_key(key)
     end
   end
   
 def self.open_dir(dir)
   curr = Dir.pwd
   Dir.chdir("#{curr}/#{dir}")
   this = Dir.pwd
   Dir.glob("*yaml") do |item|
      next if item == '.' or item == '..'
      p = use_yaml(item, this);
    end
    @dir = Dir.glob("*").select{ |f| File.directory? f}
    if !@dir.empty?
      @dir.each do |f|
        open_dir(f)
      end
    end
    Dir.chdir("#{curr}")
 end
 
end

Run.start("", ARGV[0])

