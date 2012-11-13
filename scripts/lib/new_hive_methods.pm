# This module contains several methods that I would like to see
# in the Hive API but it is unlikely that they get into it.
# 
# They are convenient to simplify constructs like:
# $obj->$method(@args);
#
# and work with (for example):
# $analysis_stats->hive_capacity(555);
# and
# $analysis->delete_param("mlss_id");
# or
# $analysis->add_param("mlss_id", 40086);
#
# The cost is not being coded in the class itself
#

package new_hive_methods;

use strict;
use warnings;
no warnings "once";

use Bio::EnsEMBL::Hive::Utils qw/stringify destringify/;

# delete_param deletes a single param in the param table by key
# It is injected in the Analysis object directly so it works as a 
# native method of the object
*Bio::EnsEMBL::Hive::Analysis::delete_param = sub {
    my ($self, $key) = @_;
    my $curr_raw_parameters = $self->parameters;
    my $curr_parameters = Bio::EnsEMBL::Hive::Utils->destringify($curr_raw_parameters);
    delete $curr_parameters->{$key};
    my $new_raw_parameters = Bio::EnsEMBL::Hive::Utils->stringify($curr_parameters);
    $self->parameters($new_raw_parameters);
    return;
};

# add_param adds/change a single param in the param table by key
# It is injected in the Analysis object directly so it works as a 
# native method of the object
*Bio::EnsEMBL::Hive::Analysis::add_param = sub {
    my ($self, $key, $value) = @_;
    my $curr_raw_parameters = $self->parameters;
    my $curr_parameters = Bio::EnsEMBL::Hive::Utils->destringify($curr_raw_parameters);
    $curr_parameters->{$key} = $value;
    my $new_raw_parameters = Bio::EnsEMBL::Hive::Utils->stringify($curr_parameters);
    $self->parameters($new_raw_parameters);
    return;
};

# update_module evaluates its argument in order to 
# determine if the module exists and is in the path
# Then calls the "module" method of the Analysis adaptor
*Bio::EnsEMBL::Hive::Analysis::update_module = sub {
    my ($self, $module) = @_;
    eval "require $module";
    $self->module($module);
};

# description returns the ResourceDescription object
# of a given ResourceClass
*Bio::EnsEMBL::Hive::ResourceClass::description = sub {
    my ($self) = @_;
    my $description = $self->adaptor->db->get_ResourceDescriptionAdaptor->fetch_all_by_resource_class_id($self->dbID)->[0];
    return $description;
};

# Method for retrieving the ResourceDescription adaptor from a dbID
*Bio::EnsEMBL::Hive::DBSQL::ResourceDescriptionAdaptor::fetch_by_dbID = sub {
    my ($self, $id) = @_;
    my $obj = $self->fetch_all_by_resource_class_id($id)->[0];
    return $obj;
};

# This should be fetched correctly by AnalysisStatsAdaptor now
# TODO: Test that this natively in the Adaptor and if so,
# remove this injected method from here
*Bio::EnsEMBL::Hive::DBSQL::AnalysisStatsAdaptor::fetch_by_dbID = sub {
  my ($self, $id) = @_;
  my $obj = $self->fetch_by_analysis_id($id);
  return $obj;
};

## To allow the creation of new resources (class + description) in one call
*Bio::EnsEMBL::Hive::DBSQL::ResourceClassAdaptor::create_full_description = sub {
  my ($self, $rc_name, $meadow_type, $parameters) = @_;
  for my $rc (@{$self->fetch_all}) {
    # if ($rc_name eq $rc->name) {
    #   throw("This resource name exists in the database\n");
    # }
  }
  my $rc = $self->create_new(-NAME => $rc_name);
  my $rc_id = $rc->dbID();
  $self->db->get_ResourceDescriptionAdaptor->create_new(
							-RESOURCE_CLASS_ID => $rc_id,
							-MEADOW_TYPE       => $meadow_type,
							-PARAMETERS        => $parameters,
						       );
};

## AnalysisJobAdaptor doesn't have a generic update method
## and it doesn't inherits from Hive::DBSQL::BaseAdaptor either
## I guess that this will change in the future,
## but for now I am injecting a generic update for that adaptor.
*Bio::EnsEMBL::Hive::DBSQL::AnalysisJobAdaptor::update = sub {
  my ($self, $job) = @_;
  my $sql = "UPDATE job SET input_id='" . $job->input_id . "'";
  $sql .= ",status='" . $job->status . "'";
  $sql .= ",retry_count=" . $job->retry_count;
  $sql .= ",semaphore_count=" . $job->semaphore_count;
  $sql .= ",semaphored_job_id=" . $job->semaphored_job_id;
  $sql .= " WHERE job_id=" . $job->dbID;

  my $sth = $self->prepare($sql);
  $sth->execute();
  $sth->finish();

  unless ($job->completed) {
    $self->update_status($job);
  }
};

1;

