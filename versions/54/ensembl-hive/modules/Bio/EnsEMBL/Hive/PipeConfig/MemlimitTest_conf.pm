
=pod

=head1 NAME

  Bio::EnsEMBL::Hive::PipeConfig::MemlimitTest_conf

=head1 SYNOPSIS

    init_pipeline.pl Bio::EnsEMBL::Hive::PipeConfig::MemlimitTest_conf -password <your_password>

=head1 DESCRIPTION

    This is another example pipeline built around FailureTest.pm RunnableDB. It consists of two analyses:

    Analysis_1: JobFactory.pm is used to create an array of jobs -

        these jobs are sent down the branch #2 into the second analysis

    Analysis_2: FailureTest.pm in "memory grab" mode may overrun the current resource's memory limit and be killed by the LSF

=head1 CONTACT

  Please contact ehive-users@ebi.ac.uk mailing list with questions/suggestions.

=cut

package Bio::EnsEMBL::Hive::PipeConfig::MemlimitTest_conf;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::PipeConfig::HiveGeneric_conf');  # All Hive databases configuration files should inherit from HiveGeneric, directly or indirectly


sub resource_classes {
    my ($self) = @_;
    return {
        %{$self->SUPER::resource_classes},  # inherit 'default' from the parent class

         'default'      => {'LSF' => '-C0 -M100   -R"select[mem>100]   rusage[mem=100]"' }, # to make sure it fails similarly on both farms
         '200Mb_job'    => {'LSF' => '-C0 -M200   -R"select[mem>200]   rusage[mem=200]"' },
         '400Mb_job'    => {'LSF' => '-C0 -M400   -R"select[mem>400]   rusage[mem=400]"' },
         '1Gb_job'      => {'LSF' => '-C0 -M1000  -R"select[mem>1000]  rusage[mem=1000]"' },
    };
}


sub pipeline_analyses {
    my ($self) = @_;
    return [
        {   -logic_name => 'generate_jobs',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
            -meadow_type => 'LOCAL',
            -parameters => {
                'column_names' => [ 'grab_mln' ],
            },
            -input_ids => [
                { 'inputlist' => [ 0.6 , 0.8 , 1.0 , 1.2 , 1.4 , 1.6 , 1.8 , 2.0, 2.5, 3.0, 5.0, 7.0, 10 ], },
            ],

            -flow_into => {
                2 => [ 'failure_test' ],
            },
        },

        {   -logic_name    => 'failure_test',
            -module        => 'Bio::EnsEMBL::Hive::RunnableDB::FailureTest',
            -parameters => {
                'time_RUN'      => 30,
            },
            -rc_name => 'default',      # pick a valid value from resource_classes() section
        },
    ];
}

1;

