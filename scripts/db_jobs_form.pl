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

use Bio::EnsEMBL::Hive::DBSQL::DBAdaptor;

use JSON;
use HTML::Template;
use Data::Dumper;

use lib ("./lib");
use version_check;

my $json_data = shift @ARGV || '{"version":["53"],"url":["mysql://ensro@127.0.0.1:2912/mp12_compara_nctrees_70hmm"]}';

# Input
my $var = decode_json($json_data);
my $url = $var->{url}->[0];
my $version = $var->{version}->[0];

# Set up @INC and paths for static content
my $project_dir = $ENV{GUIHIVE_BASEDIR};
my $jobs_form_template = $project_dir . "static/jobs_form.html";

# Initialization
my $dbConn = Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new( -no_sql_schema_version_check => 1, -url => $url );

if (defined $dbConn) {

  ## First check if the code version is OK
  ## TODO: We are just exiting here if we have a version mismatch.
  ##       I don't know if this is the best thing to do, though
  my $code_version = get_hive_code_version();
  my $hive_db_version = get_hive_db_version($dbConn);

  if ($code_version != $hive_db_version) {
    exit 0;
  }

  my $form = formJobsForm($dbConn);
  print $form;
}


sub formJobsForm {
  my ($dbConn) = @_;

  my $all_analysis = $dbConn->get_AnalysisAdaptor()->fetch_all();
  my @values = (map {{analysis_id => $_->dbID, analysis_display => "analysis_".$_->dbID." (".$_->logic_name.")"}} @$all_analysis);

  unshift @values, {
		    'analysis_display' => '',
		    'analysis_id' => ''
		   };

  my $template = HTML::Template->new(filename => $jobs_form_template);
  $template->param('values' => [@values]);
  return $template->output();
}