#! /usr/bin/env ruby

lib_path = File.expand_path(File.dirname(__FILE__)) + "/lib/"
$LOAD_PATH << lib_path unless $LOAD_PATH.include? lib_path

require 'rubygems'
require 'bundler'
Bundler.require
require 'sudokill'

Sudokill.start!(:server, :production, :background => true)
Sudokill.start!(:web, :production, :background => true, :web => :only)