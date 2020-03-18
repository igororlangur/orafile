require 'oci8'
require 'io/console'

VERSION = '0.0'
def dir_list (directory,sort,order,number)
  sql = "SELECT type, filesize, mtime, filename "
  sql = sql + "FROM table(rdsadmin.rds_file_util.listdir('#{directory}')) order by type"
  case sort
  when 'M' then sql = sql + ',MTIME desc'
  when 'A' then sql = sql + ',FILENAME'
  end
  if number
    sql = sql + " FETCH FIRST #{number} ROWS ONLY" if order == 'Head'
    if  order == 'Tail'
      sql = <<-SQL_TEXT
select  type, filesize,mtime,filename from (
     select type, filesize,mtime,filename,ROWNUM rn ,max(ROWNUM) OVER () rn_max  from (
        #{sql}
      )
) where rn_max-rn < #{number}
SQL_TEXT
    end
  end
  # puts sql
  result = []
  #.fetch_hash
  nrow = $conn.exec(sql) do |r|
    r[1] = r[1].to_i.to_s
    r[2] = r[2].to_s
    result << r
  end
  # define max size each columns
  width = []
  (0..3).each { |i| width[i] = result.map { |e| e[i].size }.max }
  #output result
  puts
  result.each { |row| puts "#{row[0].ljust(width[0])} #{row[1].rjust(width[1])} #{row[2].ljust(width[2])}\t#{row[3].ljust(width[3])}"  }
  # row.each_with_index.map { |l,i| l.ljust(width[i]) }.join("\t")
end

# the procedure shows a content of the file
def view_file (directory,file,order,number)
  sql = 'SELECT text '
  # if we want to see the tail of the file we will add some addidtional column to sort
  sql = sql + ',ROWNUM rn ,max(ROWNUM) OVER () rn_max ' if  order == 'Tail'
  sql = sql + "FROM table(rdsadmin.rds_file_util.read_text_file('#{directory}','#{file}'))"
  # .... and using subquery
  sql='select text from (' + sql + ')' if  order == 'Tail'
  if number
    sql = sql + " where rn_max-rn < #{number}" if  order == 'Tail'
    sql = sql + " FETCH FIRST #{number} ROWS ONLY" if order == 'Head'
  end
#  puts sql
  puts
  nrow = $conn.exec(sql) do |r|
	   puts "#{r[0]}"
  end
end

USAGE = <<ENDUSAGE
Usage:
   #{File.basename(__FILE__)} [-h] [-v] -u username [-p password] -b datatbase -a (List|View|Load) -d directory [-f filename] [-n number [-o (Head|Tail)]] [-s (M|A|N)] [-P path] [-t (RDS)]
ENDUSAGE

HELP = <<ENDHELP

Parameters:
   -h, --help       Show this help.
   -v, --version    Show the version number
   -u, --user       User name to connect to the database
   -p, --password   Password for connection to the database
   -b, --database   Connection string to the database It might a TNS alias (see tnsnames.ora)or easy connect string (//server:port/service_name)
   -d, --directory  The oracle directory (see ALL_DIRTORIES view)
   -a, --action     It might take the following values:
                 List - give the list of files from the directory
                 View - show the file content
                 Load - load file to the local disk
   -f, --file      For Load and View actions it sets the file name
   -n, --number    For List and View actions it is number of demonstrated rows
   -o, --order     For List and View actions and if number option is set it determines which number of lines to show from the beginning or the end.
                 Head - top lines (default)
                 Tail - bottom lines
   -s, --sort      For List action it specifies the sort order. It might be the following
                  M - data modification file
                  A - file name
                  N - without sort (default)
   -P, --path      For Load option  it sets the path to save loaded file
   -t, --type RDS TODO

ENDHELP

ARGS = {:sort=>'N', :order=>'Head', :type=>'RDS' } # Setting default values
ARGT = {:action=>['List','View','Load'],:order=>['Head','Tail'],:sort=>['N','A','M'],:type=>['RDS']}
# parse comand line paramente https://stackoverflow.com/questions/26434923/parse-command-line-arguments-in-a-ruby-script
next_arg = nil
ARGV.each do |arg|
  case arg
    when '-h','--help'       then ARGS[:help] = true
    when '-v','--version'    then ARGS[:version] = true
    when '-u', '--user'      then next_arg = :user
    when '-p', '--password'  then next_arg = :password
    when '-b', '--database'  then next_arg = :database
    when '-a', '--action'    then next_arg = :action
    when '-d', '--directory' then next_arg = :directory
    when '-f', '--file'      then next_arg = :file
    when '-n', '--number'    then next_arg = :number
    when '-o', '--order'     then next_arg = :order
    when '-s', '--sort'      then next_arg = :sort
    when '-P', '--path'      then next_arg = :path
    when '-t', '--type'      then next_arg = :type
    else
      if next_arg
        if next_arg == :sort or next_arg == :type
          ARGS[next_arg] = arg.upcase
        elsif next_arg == :action or next_arg == :order
          ARGS[next_arg] = arg.capitalize
        else
          ARGS[next_arg] = arg
        end
      end
      next_arg = nil
  end
end
# show version
if  ARGS[:version]
  puts "\n#{File.basename(__FILE__)}: #{VERSION}"
  exit
end

# check that all mandatory parameter is set
h=false
if ARGS[:help] or !ARGS[:action] or !ARGS[:directory] or !ARGS[:database]  or !ARGS[:user]
  h=true
end
# if all is set it will check the value from the values list
unless h
  ARGT.each do |k,vals|
    if ARGS[k]
      h=true unless vals.include? ARGS[k]
    end
  end
end

if h
  print "One of mandatory parameters was not set\n\n" unless  ARGS[:help]
  puts USAGE
  puts HELP
  exit
end

# Ask password if it wasn't set
ARGS[:password] = IO::console.getpass "Enter Password: " unless ARGS[:password]


# Connect to Oracle DB
$conn = OCI8.new("#{ARGS[:user]}/\"#{ARGS[:password]}\"\@#{ARGS[:database]}")

case ARGS[:action]
  when 'Load' then
    bfile = OCI8::BFILE.new($conn, ARGS[:directory], ARGS[:file])
    fn = ARGS[:file]
    fn = File.join(ARGS[:path] , fn) if ARGS[:path]
    print "Load file #{ARGS[:file]}"
    File.open(fn, 'w') do |f|
      f.write(bfile.read)
    end
    puts " ---- to #{fn}"
  when 'View' then  view_file ARGS[:directory], ARGS[:file], ARGS[:order], ARGS[:number]
  when 'List' then  dir_list  ARGS[:directory], ARGS[:sort], ARGS[:order], ARGS[:number]
end

$conn.logoff
