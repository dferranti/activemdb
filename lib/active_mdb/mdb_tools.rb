module MDBTools

  include ActiveSupport::Inflector
  extend self

  DELIMITER = '::'
  LINEBREAK = "\n"
  SANITIZER = /^\w\.\_/ # dumb filter for SQL arguments
  BACKENDS = %w{ access mysql oracle postgres sybase }


  class MDBToolsError < StandardError ; end

  # test for existence and usability of file
  def check_file(mdb_file)
    raise MDBToolsError, "File not found: #{mdb_file}" unless File.exist?(mdb_file)
    @mdb_version = `mdb-ver #{mdb_file} 2>&1`.chomp
    if $? != 0
      raise MDBToolsError, "mdbtools cannot access #{mdb_file}"
    end
    mdb_file
  end

  # runs mdb_version.  A blank version indicates an unusable file
  def valid_file?(file)
    !mdb_version(file).blank?
  end

  def mdb_version(file)
    `bin/mdbtools/mdb-ver #{file} 2> /dev/null`.chomp
  end

  # raises an MDBToolsError unless the mdb file contains a table with the specified name.
  # returns the table name, otherwise.
  def check_table(mdb_file, table_name)
    unless mdb_tables(mdb_file).include?(table_name)
      raise MDBToolsError, "mdbtools does not think a table named \"#{table_name}\" exists"
    end
    table_name
  end

  # uses mdb-tables tool to return an array of table names.
  # You can filter the tables by passing an array of strings as
  # either the :exclude or :include key to the options hash.
  # The strings will be ORed into a regex.  Only one or the other of
  # :exclude or :include, please.
  #
  # ex. mdb_tables('thing.mdb', :exclude => ['_Lookup'])
  #
  # ex. mdb_tables('thing.mdb', :include => ['tbl'])
  def mdb_tables(mdb_file, options = {})
    included, excluded = options[:include], options[:exclude]
    return `bin/mdbtools/mdb-tables -1 #{mdb_file}`.split(LINEBREAK) if not (included || excluded)
    raise MDBToolsError if (options[:include] && options [:exclude])
    if options[:exclude]
      regex = Regexp.new options[:exclude].to_a.join('|')
      tables = `bin/mdbtools/mdb-tables -1 #{mdb_file}`.split(LINEBREAK).delete_if { |name| name =~ regex }
    end
    if options[:include]
      regex = Regexp.new options[:include].to_a.join('|')
      tables = `bin/mdbtools/mdb-tables -1 #{mdb_file}`.split(LINEBREAK).select { |name| name =~ regex }
    end
    tables
  end

  # takes an array of field names
  # and some conditions to append in a WHERE clause
  def sql_select_where(mdb_file, table_name, attributes = nil, conditions=nil)
    if attributes.respond_to?(:join)
      attributes = attributes.collect {|a| "\"#{a}\"" }.join(' ')
    elsif attributes.kind_of?(String)
      attributes = "\"#{attributes}\""
    else
      attributes ||= '*'
    end
    where = conditions ? "where #{conditions}" : ""
    sql = "select #{attributes} from #{table_name} #{where}"
    mdb_sql(mdb_file, sql)
  end

  # forks an IO.popen running mdb-sql and discarding STDERR to /dev/null.
  # The sql argument should be a single statement, 'cause I don't know
  # what will happen otherwise.  mdb-sql uses "\ngo" as the command terminator.
  def mdb_sql(mdb_file,sql)
    # libMDB barks on stderr quite frequently, so discard stderr entirely
    command = "bin/mdbtools/mdb-sql -Fp -d '#{DELIMITER}' #{mdb_file} 2> /dev/null \n"
    array = []
    IO.popen(command, 'r+') do |pipe|
      pipe << "#{sql}\ngo\n"
      pipe.close_write
      pipe.readline
      fields = pipe.readline.chomp.split(DELIMITER)
      full_line = []
      pipe.each do |row|
        hash = {}
        row = row.split(DELIMITER)
        if !full_line.empty? && full_line.size < fields.size
          full_line.last << " "
          full_line.last << row.first
          row.delete(row.first)
        end
        full_line << row.map{|col| col.chomp}
        full_line.flatten!

        #fixing '\r\n' symbols in memo fields type. In old implementation this breaks the result by splitting it to a couple dataset rows
        next unless full_line.size == fields.size

        fields.each_index do |i|
          hash[fields[i]] = full_line[i]
        end
        array << hash
        full_line = []
      end
    end
    array
  end

  # uses mdb-sql to retrieve an array of the table's field names
  def field_names_for(mdb_file, table)
    fields = `echo -n 'select * from #{table} where 1 = 2' | bin/mdbtools/mdb-sql -Fp -d '#{DELIMITER}' #{mdb_file}`.chomp.sub(/^\n+/, '')
    fields.split(DELIMITER)
  end


  # takes a hash where keys are column names, values are search values
  # and returns a string that you can use in a WHERE clause
  #
  # ex. compile_conditions(:first_name => 'Summer', :last_name => 'Roberts') 
  # gives "first_name like '%Summer%' AND last_name like '%Roberts%'
  #
  # if you want to use an operator other than LIKE, give compile_conditions
  # a block that accepts column_name and value and does something interesting
  #
  # compile_conditions(:age => 18) {|name, value| "#{name} = #{value}"}
  #
  # the condition phrases are all ANDed together before insertion into a WHERE clause
  def compile_conditions(conditions_hash)
    conditions = conditions_hash.sort_by{|k,v| k.to_s}.map do |column_name, value|
      if block_given?
        yield column_name, value
      else
        "#{column_name} like '%#{value}%'"
      end
    end.join(' AND ')
  end

  # really dumb way to get a count.  Does a SELECT and call size on the results
  def faked_count(*args)
    sql_select_where(*args).size
  end

  # convenience method, not really used with ActiveMDB.  
  # Valid options are :format, :headers, and :sanitize, 
  # which correspond rather directly to the underlying mdb-export arguments.
  # Defaults to :format => 'sql', :headers => false, :sanitize => true
  def mdb_export(mdb_file, table_name, options = {})
    defaults = {  :format => 'sql',
                  :headers => false,
                  :sanitize => true  }
    options = defaults.merge options

    args = []
    if options[:delimiter]
      args << "-d #{options[:delimiter].dump}"
    elsif options[:format] == 'sql'
      args << "-I "
    elsif options[:format] == 'csv'
      args << "-d ',' "
    else
      raise MDBToolsError, "Unknown format:  #{options[:format]}"
    end

    args << "-H " unless options[:headers] == true
    args << "-S" unless options[:sanitize] == false
    `bin/mdbtools/mdb-export #{args} #{mdb_file} #{table_name.to_s.dump}`
  end

  # wrapper for DESCRIBE TABLE using mdb-sql
  def describe_table(mdb_file, table_name)
    command = "describe table \"#{table_name}\""
    mdb_sql(mdb_file,command)
  end

  # wrapper for mdb-schema, returns SQL statements
  def mdb_schema(mdb_file, table_name)
    schema = `bin/mdbtools/mdb-schema -T #{table_name.dump} #{mdb_file}`
  end

  # convenience method for mdb_export to output CSV with headers.
  def table_to_csv(mdb_file, table_name)
    mdb_export(mdb_file, table_name, :format => 'csv', :headers => true)
  end

  def delimited_to_arrays(text)
    text.gsub!(/\r\n/,' ')
    text.split(LINEBREAK).collect { |row| row.split(DELIMITER)}
  end

  def arrays_to_hashes(headers, arrays)
    arrays.collect do |record|
      record_hash = Hash.new
      until record.empty? do
        headers.each do |header|
          record_hash[header] = record.shift
        end
      end
      record_hash
    end
  end


  # helper to turn table names into standard format method names.
  # Inside, it's just ActionView::Inflector.underscore
  def methodize(table_name)
    ActiveSupport::Inflector.underscore table_name
  end

  def backends
    BACKENDS
  end

  # poor, weakly sanitizing gsub!.
  def sanitize!(string)
    string.gsub!(SANITIZER, '')
  end

  # mdb-tools recognizes 1 and 0 as the boolean values.
  # Make it so.
  def mdb_truth(value)
    case value
    when false
      0
    when true
      1
    when 0
      0
    when 1
      1
    when "0"
      0
    when "1"
      1
    end
  end

end
