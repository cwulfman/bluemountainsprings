# Blue Mountain Springs: A RESTful API to Blue Mountain

This repository contains implementation of Blue Mountain Springs, an API to Blue Mountain, a digital library of avant-garde magazines.

It is written in XQuery and XSLT and uses [eXist-db](http://exist-db.org/exist/apps/homepage/index.html), version 3.

For more documentation about Blue Mountain Springs, see [the home page](http://princeton-cdh.github.io/bluemountainsprings/).

For more documentation about Blue Mountain, visit [Blue Mountain](http://bluemountain.princeton.edu)
or its GitHub [GitHub pages](https://github.com/pulibrary/BlueMountain).

In 2015-2016, Blue Mountain Springs was sponsored by the [Center for Digital Humanities at Princeton](http://digitalhumanities.princeton.edu/).

## Code Organization
This version of Blue Mountain Springs is deployed as an eXist-db application]. See the [eXist-db documentation](http://exist-db.org/exist/apps/doc/development-starter.xml) for a full description of the directory structure.

## Known Dependencies
* eXist-db version 3.0
* Blue Mountain Springs is known to run under OS X 10.11 and Ubuntu Linux (VERSION??).

## To Install
* clone this repository
* in the top-level directory, run `ant` to create a package jar file in the build/ directory
* install using eXist's package installer (available in eXist's Dashboard).

For this release, you will also have to import the data into your eXist database. There are two data sources: METS/ALTO data and TEI transcription data.

### Install Blue Mountain METS/ALTO/MODS into eXist-db ###

  * clone the main Blue Mountain repository
  * run ant in the db folder:
      * `ant load-conf`
      * `ant load-pilot`
 
### Install Blue Mountain TEI transcriptions into eXist-db ###

  *  clone the Blue Mountain transcriptions repository
  *  run ant in the db folder:
	 *  `ant load-conf`
	 *  `ant load-pilot`
