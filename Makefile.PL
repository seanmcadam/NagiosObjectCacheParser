use ExtUtils::MakeMaker;

WriteMakefile(
    NAME   => "NagiosObjectCacheParser",
    AUTHOR => 'Sean McAdam (sean@fredcom.com)',

    PREREQ_PM => {
        'Data::Dumper'        => 1,
        'Readonly'            => 1,
        'JSON'                => 1,
        'IPC::Shareable'      => 1,
	'APR::Const'          => 1,
        'Apache2::Const'      => 1,
        'Apache2::Log'        => 1,
        'Apache2::ServerRec'  => 1,
        'Apache2::RequestRec' => 1,
        'Apache2::ServerUtil' => 1,
    },
);

