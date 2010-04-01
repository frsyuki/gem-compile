gem-compile
===========
A RubyGems command plugin that creates pre-compiled binary gems from gems with extensions.


## Overview

gem-compile is a RubyGems command plugin that adds 'compile' command.
It creates pre-compiled binary gems from gems with extensions.


## Installation

    $ gem build gem-compile.gemspec
    $ gem install gem-compile-*.gem
or
    $ gem install gem-compile


## Usage

    $ gem compile [options] GEMFILE -- --build-flags
or
    $ gem-compile [options] GEMFILE -- --build-flags

options:
    -p, --platform PLATFORM          Output platform name
    -f, --fat VERSION:RUBY,...       Create fat binary (e.g. --fat 1.8:ruby,1.9:ruby19)


## Example

    $ gem compile msgpack-0.3.4.gem
With above command line, **msgpack-0.3.4-x86-mingw32.gem** file will be created on MinGW environment.

    $ gem compile --platform mswin32 msgpack-0.3.4.gem
With above command line, **msgpack-0.3.4-x86-mswin32.gem** file will be created.

    $ gem compile --platform mswin32 --fat 1.8:/Ruby/bin/ruby,1.9:/Ruby19/bin/ruby msgpack-0.3.4.gem
With --fat option, it creates a fat-binary. It's installable on both ruby-1.8 and ruby-1.9.


## License

    Copyright (c) 2010 FURUHASHI Sadayuki
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.

