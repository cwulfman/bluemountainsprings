[![Stories in Ready](https://badge.waffle.io/Princeton-CDH/bluemountainsprings.png?label=ready&title=Ready)](https://waffle.io/Princeton-CDH/bluemountainsprings)
# Blue Mountain Springs: A RESTful API to Blue Mountain

This repository contains implementation of Blue Mountain Springs, an API to Blue Mountain, 
a digital library of avant-garde magazines.

It is written in XQuery and XSLT and uses [eXist-db](http://exist-db.org/exist/apps/homepage/index.html), version 3.

In 2015-2016, Blue Mountain Springs was sponsored by 
the [Center for Digital Humanities at Princeton](http://digitalhumanities.princeton.edu/).

## Links to Other Resources and Documentation
 * The main documentation for Blue Mountain Springs can be found in the doc/ directory of this repository.
 * [Blue Mountain](http://bluemountain.princeton.edu)
 * [Official Blue Mountain Springs site](http://bluemountain.princeton.edu/exist/apps/bmtnsprings/index.html)
 * [Blue Mountain Springs at Princeton CDH](https://digitalhumanities.princeton.edu/projects/BlueMountainSprings/)
 * [Blue Mountain metadata repository](https://github.com/pulibrary/BlueMountain)
 * [Blue Mountain TEI transcriptions repository](https://github.com/Princeton-CDH/bluemountain-transcriptions)
 * [RESTXQ Specification](http://exquery.github.io/exquery/exquery-restxq-specification/restxq-1.0-specification.html)

## Code Organization
This version of Blue Mountain Springs is deployed as an eXist-db application.
See the [eXist-db documentation](http://exist-db.org/exist/apps/doc/development-starter.xml) 
for a full description of the directory structure.

## Known Dependencies
* eXist-db version 3.0
* Blue Mountain Springs is known to run under OS X 10.11 and Ubuntu Linux (VERSION??).

## To Install
Follow the directions in installing.html.

For this release, you will also have to import the data into your eXist database. 
There are two data sources: METS/ALTO data and TEI transcription data.

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
