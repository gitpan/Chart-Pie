use ExtUtils::MakeMaker;

#  make the samples directory
mkdir ('samples', 00755);


WriteMakefile(
   'NAME'      => 'Chart::Pie',
   'VERSION'   => '0.90',
   'PREREQ_PM' => { 'GD' => 0, 'Chart::Base' => 0.99 },
   'dist'      => { 'COMPRESS' => 'gzip', 'SUFFIX' => 'gz' }
);

