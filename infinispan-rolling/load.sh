#!/bin/sh
exec scala -J-Xmx5g -classpath ./infinispan-remote.jar -savecompiled "$0" "$@"
!#

import org.infinispan.client.hotrod._
import org.infinispan.client.hotrod.configuration._
import java.net._
import scala.collection.JavaConversions._
import scala.util.Random
import scala.io._

val usage = """

\nUsage: load.sh --entries num [--write-batch num] [--max-phrase-size num]\n

"""

if (args.length == 0) {
  println(usage)
  System.exit(1)
}

var entries = 0
var write_batch = 10000
var max_phrase_size = 10

args.sliding(2, 2).toList.collect {
  case Array("--entries", num: String) => entries = num.toInt
  case Array("--write-batch", num: String) => write_batch = num.toInt
  case Array("--max_phrase_size", num: String) => max_phrase_size = num.toInt
}

if(entries <= 0) {
   println("option 'entries' is required")
   println(usage)
   System.exit(1)
}

println(s"\nLoading $entries entries with write batch size of $write_batch and max phrase size of $max_phrase_size\n")

val wordList = Source.fromFile("/usr/share/dict/words").getLines.foldLeft(Vector[String]())( (s, w) => s :+ w)

val sz = wordList.size

val rand = new Random()

def randomWord = wordList(rand.nextInt(sz))

def randomPhrase = (0 to rand.nextInt(max_phrase_size)).map(i => randomWord).mkString(" ")

val clientBuilder = new ConfigurationBuilder

clientBuilder.addServer().host(InetAddress.getLocalHost.getHostAddress).port(11222)
val rcm = new RemoteCacheManager(clientBuilder.build)
val cache = rcm.getCache[Int,String]
cache.clear

(1 to entries)
     .map(_ -> randomPhrase)
     .grouped(write_batch).toStream.par
     .map(m => mapAsJavaMap(m.toMap))
     .foreach(m => cache.putAll(m))

