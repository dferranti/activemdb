#### ActiveMDB

by Matthew King
http://rubyforge.org/projects/activemdb/

with changes by Pilgun Boris (pilgun.boris@gmail.com) for specific system.

### CHANGES:

- added support for rails 3.2.x
- removed support of ActiveRecord for mdb tables
- commented out unusable code

### DESCRIPTION:
  
ActiveMDB is a developer's tool for exploration and migration of MS Access (.mdb) files. Yes, it is  *READ ONLY*. ActiveMDB is little more than a wrapper of varying thickness around the utilities from Brian Bruns's MDB Tools project (http://mdbtools.sourceforge.net/).  Kudos to Mr. Bruns.


### REQUIREMENTS:

- http://mdbtools.sourceforge.net/

### INSTALL MDBTools:

- on ubuntu: `sudo apt-get install mdbtools`
- on Mac OS X: `brew install mdbtools`
- sources: http://mdbtools.sourceforge.net/  (not tested)
- to check installation use: `man mdb-sql`

### HOW TO USE:

- add to you Gemfile: `gem 'activemdb', git: 'https://github.com/pilgunboris/activemdb.git'`
- add `require 'active_mdb'` and `extend MDBTools` to file where you will use this
- code examples:

		check_table(filename, table_name)		#will check table presence
		mdb_sql(mdb_local_file_name, "SELECT * FROM users")  #supports only simple queries (see `man mdb-sql`)

- if something went wrong it will raise 'MDBToolsError'
- for more information look at /lib/active_mdb/mdb_tools.rb


### LICENSE:

(The MIT License)

Copyright (c) 2007 

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
