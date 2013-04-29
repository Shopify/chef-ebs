# Original source: https://github.com/scalarium/cookbooks/tree/master/ebs
# Updated by Jonathan Rudenberg (jonathan@titanous.com)

name "ebs"
maintainer "Jonathan Rudenberg"
maintainer_email "jonathan@titanous.com"
description "Mounts attached EBS volumes"
version "0.3"
recipe "ebs::volumes", "Mounts attached EBS volumes"
recipe "ebs::raids", "Mounts attached EBS RAIDs"

depends 'aws'
