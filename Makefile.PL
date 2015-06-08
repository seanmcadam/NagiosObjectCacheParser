use ExtUtils::MakeMaker;

WriteMakefile(
    NAME   => "NagiosObjectCacheParser",
    AUTHOR => 'Sean McAdam (sean@fredcom.com)',

    PREREQ_PM => {
        'Data::Dumper'        => 0,
        'Readonly'            => 0,
        'JSON'                => 0,
	'IPC::Shareable'      => 0,
    },
);

