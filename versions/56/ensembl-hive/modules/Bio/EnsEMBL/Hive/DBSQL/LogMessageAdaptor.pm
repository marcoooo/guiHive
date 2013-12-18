=pod

=head1 NAME

    Bio::EnsEMBL::Hive::DBSQL::LogMessageAdaptor

=head1 SYNOPSIS

    $dba->get_LogMessageAdaptor->store_job_message($job_id, $msg, $is_error);

    $dba->get_LogMessageAdaptor->store_worker_message($worker_id, $msg, $is_error);

=head1 DESCRIPTION

    This is currently an "objectless" adaptor that helps to store either warning-messages or die-messages generated by jobs

=head1 LICENSE

    Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

    Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

         http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software distributed under the License
    is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and limitations under the License.

=head1 CONTACT

    Please contact ehive-users@ebi.ac.uk mailing list with questions/suggestions.

=cut


package Bio::EnsEMBL::Hive::DBSQL::LogMessageAdaptor;

use strict;

use base ('Bio::EnsEMBL::Hive::DBSQL::NakedTableAdaptor');


sub default_table_name {
    return 'log_message';
}


sub store_job_message {
    my ($self, $job_id, $msg, $is_error) = @_;

    chomp $msg;   # we don't want that last "\n" in the database

    my $table_name = $self->table_name();

        # Note: the timestamp 'time' column will be set automatically
    my $sql = qq{
        INSERT INTO $table_name (job_id, worker_id, retry, status, msg, is_error)
                           SELECT job_id, worker_id, retry_count, status, ?, ?
                             FROM job WHERE job_id=?
    };

    my $sth = $self->prepare( $sql );
    $sth->execute( $msg, $is_error ? 1 : 0, $job_id );
    $sth->finish();
}


sub store_worker_message {
    my ($self, $worker_id, $msg, $is_error) = @_;

    chomp $msg;   # we don't want that last "\n" in the database

    my $table_name = $self->table_name();

        # Note: the timestamp 'time' column will be set automatically
    my $sql = qq{
        INSERT INTO $table_name (worker_id, status, msg, is_error)
                           SELECT worker_id, status, ?, ?
                             FROM worker WHERE worker_id=?
    };
    my $sth = $self->prepare( $sql );
    $sth->execute( $msg, $is_error ? 1 : 0, $worker_id );
    $sth->finish();
}

1;

