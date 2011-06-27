= rubygems-sandbox

home :: https://github.com/seattlerb/rubygems-sandbox
rdoc :: http://seattlerb.rubyforge.org/rubygems-sandbox

== DESCRIPTION:

The sandbox plugin for rubygems helps you manage your command-line
tools and their dependencies. Sandboxed gems are installed in their
own private rubygem repositories with all of their dependencies. This
means that you don't have to have a rat's nest of gems in your global
repository in order to run popular command-tools like rdoc, flog,
flay, rcov, etc.

gem sandbox has the following sub-commands:

  * install gem_name ...             - install 1 or more gems
  * plugin  gem_name plugin_name ... - install a gem and plugins for it
  * remove  gem_name ...             - uninstall 1 or more gems
  * help                             - show this output

Once you install gem sandbox will output something like:

    Copy the following scripts to any directory in your path to use them:

    cp /Users/USER/.gem/sandboxes/GEM/bin/TOOL _in_your_$PATH_

Copy the scripts to a directory in your path (eg ~/bin or /usr/bin)
and you're good to go.

== SYNOPSIS:

  % gem uninstall flog flay ruby_parser sexp_processor
  % gem sandbox install flog flay
  % cp ~/.gem/sandboxes/*/bin/* ~/bin
  % flay whatever

== REQUIREMENTS:

* rubygems 1.4 or higher

== INSTALL:

* sudo gem install rubygems-sandbox

== LICENSE:

(The MIT License)

Copyright (c) Ryan Davis, seattle.rb

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
