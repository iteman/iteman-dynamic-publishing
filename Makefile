# ITEMAN Dynamic Publishing - A Perl based dynamic publishing extension for Moveble Type
# Copyright (c) 2009 ITEMAN, Inc. All rights reserved.
#
# This file is part of ITEMAN Dynamic Publishing.
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

PLUGIN_NAME = ITEMANDynamicPublishing
PLUGIN_VERSION = $(shell grep "VERSION = '[0-9]\+\.[0-9]\+\.[0-9]\+'" $(PLUGIN_NAME).pl | sed -e 's/^.*\([0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1/')

TARGETS = Changes \
	ITEMANDynamicPublishing.pl \
	README \
	bin \
	lib \
	tmpl

all: dist

dist:
	echo $(PLUGIN_NAME)-$(PLUGIN_VERSION).zip
	mkdir -p build/$(PLUGIN_NAME)
	cp -r $(TARGETS) build/$(PLUGIN_NAME)
	mkdir -p build/$(PLUGIN_NAME)/tmp
	find build/$(PLUGIN_NAME) -type d | xargs chmod 755
	find build/$(PLUGIN_NAME) -type f | xargs chmod 644
	chmod 755 build/$(PLUGIN_NAME)/bin/*.cgi
	mkdir dist
	cd build; \
	zip -r ../dist/$(PLUGIN_NAME)-$(PLUGIN_VERSION).zip $(PLUGIN_NAME)

clean:
	rm -rf build
	rm -rf dist

# Local Variables:
# mode: makefile-gmake
# coding: iso-8859-1
# tab-width: 4
# c-basic-offset: 4
# c-hanging-comment-ender-p: nil
# indent-tabs-mode: t
# End:
