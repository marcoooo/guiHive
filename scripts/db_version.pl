#!/usr/bin/env perl

=pod

 Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.


=cut


use strict;
use warnings;

## The servers should have already set the PERL5LIB to point to the latest hive API in versions
use Bio::EnsEMBL::Hive::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Hive::DBSQL::SqlSchemaAdaptor;
use Bio::EnsEMBL::Hive::Utils::URL;

use JSON;

use lib ("../lib");
use msg;

my $json_url = shift @ARGV || '{"url":["mysql://ensro@127.0.0.1:2914/mp12_compara_nctrees_74sheep"]}';

# Input data
my $url = decode_json($json_url)->{url}->[0];

my $response = msg->new();

# Initialization
my $dbConn;
eval {
  $dbConn = Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new( -no_sql_schema_version_check => 1, -url => $url );
};

if ($@) {
  $response->err_msg($@);
  $response->status("FAILED");
}

if (defined $dbConn) {
  ## Check db_connection
  my $hive_db_version;
  eval {
    $hive_db_version = get_hive_db_version($dbConn);
  };
  if ($@) {
    $response->err_msg($@);
    $response->status("FAILED");
    print $response->toJSON;
    exit(0);
  }

  if (defined $hive_db_version) {
    my $parsed_url = Bio::EnsEMBL::Hive::Utils::URL::parse($url);
    my $json_obj = { 'user'       => $parsed_url->{user},
		     'dbname'     => $parsed_url->{dbname},
		     'host'       => $parsed_url->{host},
		     'port'       => $parsed_url->{port},
		     'passwd'     => $parsed_url->{pass},
		     'db_version' => $hive_db_version,
		   };

    $response->out_msg($json_obj);
  } else {
    $response->err_msg("No version found for db");
    $response->status("FAILED");
  }
} else {
  $response->err_msg("The provided URL seems to be invalid. Please check the URL and try again\n") unless($response->err_msg);
  $response->status("FAILED");
}

print $response->toJSON();

#######################
#  This method is also defined in scripts/db_connect.pl
sub get_hive_db_version {
  my ($dbConn) = @_;
  my $metaAdaptor      = $dbConn->get_MetaAdaptor;
  my $db_sql_schema_version;
  eval {
    if ($metaAdaptor->can('fetch_value_by_key')) {
      $db_sql_schema_version = $metaAdaptor->fetch_value_by_key( 'hive_sql_schema_version' );
    } elsif ($metaAdaptor->can('get_value_by_key')) {
      $db_sql_schema_version = $metaAdaptor->get_value_by_key( 'hive_sql_schema_version' );
    } else {
      $db_sql_schema_version = eval { $metaAdaptor->fetch_by_meta_key( 'hive_sql_schema_version' )->{'meta_value'}; };
    }
  };
  return $db_sql_schema_version;
}